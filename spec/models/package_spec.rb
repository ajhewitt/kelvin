require "rails_helper"

RSpec.describe Package, type: :model do
  it "instantiates the subclass named by its type" do
    expect(Package.new(type: "Keg")).to be_a(Keg)
  end

  it "requires one of the package types" do
    expect(Package.new(volume: 5, unit: "gal")).not_to be_valid
  end

  it "treats kegs and casks as cooperage" do
    expect(Package::TYPES.index_with { |type| Package.new(type: type).cooperage? })
      .to eq("Keg" => true, "Cask" => true, "Bottle" => false, "Can" => false)
  end

  it "separates cooperage from packaged drinks" do
    keg = Keg.create!(volume: 5, unit: "gal")
    can = Can.create!(volume: 0.125, unit: "gal")

    expect(Package.cooperage).to eq([keg])
    expect(Package.packaged).to eq([can])
  end

  it "rejects units other than gallons, imperial gallons and liters" do
    expect(Keg.new(volume: 1, unit: "barrel")).not_to be_valid
  end

  it "allows each type, volume and unit combination once" do
    Can.create!(volume: 0.125, unit: "gal")

    expect(Can.new(volume: 0.125, unit: "gal")).not_to be_valid
    expect(Bottle.new(volume: 0.125, unit: "gal")).to be_valid
  end

  it "can't be deleted while it's on an event's list" do
    keg = Keg.create!(volume: 5, unit: "gal")
    event = Event.create!(name: "Party", date: Date.new(2026, 11, 14))
    event.drink_packages.create!(drink: Drink.create!(name: "Mild"), package: keg)

    expect(keg.destroy).to be(false)
    expect(Package.exists?(keg.id)).to be(true)
  end

  it "keeps its type, since drinks on lists would change sides" do
    keg = Keg.create!(volume: 5, unit: "gal")

    expect { keg.update(type: "Bottle") }.to raise_error(ActiveRecord::ReadonlyAttributeError)
  end

  describe "sizes typed as printed" do
    {
      ["12", "oz"] => [0.09375, "gal"],
      ["660", "ml"] => [0.66, "liter"],
      ["20", "imp oz"] => [0.125, "imp_gal"],
      ["5", "gal"] => [5, "gal"],
      ["4.5", "imp gal"] => [4.5, "imp_gal"],
      ["20", "L"] => [20, "liter"]
    }.each do |(amount, measure), (volume, unit)|
      it "stores #{amount} #{measure} as #{volume} #{unit}" do
        package = Can.new(amount: amount, measure: measure)

        expect(package).to be_valid
        expect([package.volume, package.unit]).to eq([volume, unit])
      end
    end

    it "shows a stored size the way it's typed" do
      package = Bottle.create!(volume: 0.66, unit: "liter")

      expect([package.amount, package.measure]).to eq(["660", "ml"])
    end

    it "spots a size that's already a package of the same type" do
      Can.create!(amount: "16", measure: "oz")

      expect(Can.new(amount: "16", measure: "oz")).not_to be_valid
      expect(Bottle.new(amount: "16", measure: "oz")).to be_valid
    end

    it "rejects sizes that aren't numbers or measures" do
      expect(Can.new(amount: "a pint", measure: "oz")).not_to be_valid
      expect(Can.new(amount: "1", measure: "pint")).not_to be_valid
    end
  end

  describe "#board_size" do
    it "shows a bottle's size, as a bare number for millilitres" do
      expect(Bottle.new(volume: 0.66, unit: "liter").board_size).to eq("(660)")
      expect(Bottle.new(volume: 0.09375, unit: "gal").board_size).to eq("(12 oz)")
      expect(Bottle.new(volume: 1.5, unit: "liter").board_size).to eq("(1.5 L)")
    end

    it "leaves cans, kegs and casks without a size" do
      expect([Can.new(volume: 0.44, unit: "liter"), Keg.new(volume: 5, unit: "gal"), Cask.new(volume: 4.5, unit: "imp_gal")].map(&:board_size))
        .to all(be_nil)
    end
  end

  describe "#volume_label" do
    {
      [Keg, 5, "gal"] => "5 gal",
      [Cask, 4.5, "imp_gal"] => "4.5 imp gal",
      [Keg, 20, "liter"] => "20 L",
      [Can, 0.125, "gal"] => "16 oz",
      [Bottle, 0.09375, "gal"] => "12 oz",
      [Bottle, 0.125, "imp_gal"] => "20 imp oz",
      [Bottle, 0.66, "liter"] => "660 ml"
    }.each do |(package_class, volume, unit), label|
      it "shows #{volume} #{unit} as #{label}" do
        expect(package_class.new(volume: volume, unit: unit).volume_label).to eq(label)
      end
    end
  end
end
