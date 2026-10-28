require "rails_helper"

RSpec.describe DrinkPackage, type: :model do
  let(:event) { Event.create!(name: "Party", date: Date.new(2026, 11, 14)) }
  let(:keg) { Keg.create!(volume: 5, unit: "gal") }
  let(:cask) { Cask.create!(volume: 4.5, unit: "imp_gal") }
  let(:can) { Can.create!(volume: 0.125, unit: "gal") }

  let(:st_mars) { Brand.create!(name: "St. Mars of the Desert") }
  let(:cider_hill) { Brand.create!(name: "Cider Hill Cellars") }

  def list(name, abv, package, brand = nil, **options)
    event.drink_packages.create!(drink: Drink.create!(name: name, abv: abv, brand: brand), package: package, **options)
  end

  def side(packages)
    event.drink_packages.joins(:package).merge(packages).includes(:drink).order(:position)
      .map { |item| [item.position, item.drink.name] }
  end

  it "fills each side in ABV order as drinks are added" do
    list("Porter", 5, keg)
    list("Mild", 3.2, cask)
    list("Urchin", 6.1, can)
    list("Wheat Wine", 12, keg)
    list("Bitter", 4.2, keg)
    list("Festbier", 4.5, can)

    expect(side(Package.cooperage)).to eq([[1, "Mild"], [2, "Bitter"], [3, "Porter"], [4, "Wheat Wine"]])
    expect(side(Package.packaged)).to eq([[1, "Festbier"], [2, "Urchin"]])
  end

  it "keeps drinks without an ABV at the end of their section" do
    list("Mystery", nil, keg)
    list("Porter", 5, keg)
    list("Mild", 3.2, keg)

    expect(side(Package.cooperage)).to eq([[1, "Mild"], [2, "Porter"], [3, "Mystery"]])
  end

  it "keeps ABV order within each brand, with a brand new to the side starting at the bottom" do
    list("Barbapapa", 10, can, st_mars)
    list("Winter", 12.5, can, cider_hill)
    list("Civilization Machine", 3.7, can, st_mars)
    list("Strawberry Harvest", 8, can, cider_hill)
    list("Ludlow Lager", 5, can)

    expect(side(Package.packaged)).to eq([
      [1, "Civilization Machine"], [2, "Barbapapa"],
      [3, "Strawberry Harvest"], [4, "Winter"],
      [5, "Ludlow Lager"]
    ])
  end

  it "only rejects a taken position on the same side" do
    list("Mild", 3.2, keg)

    expect(event.drink_packages.new(drink: Drink.create!(name: "Urchin"), package: can, position: 1)).to be_valid
    expect(event.drink_packages.new(drink: Drink.create!(name: "Bitter"), package: cask, position: 1)).not_to be_valid
  end

  it "lists a drink once per package, though it can come in another" do
    drink = Drink.create!(name: "Retro Pride", abv: 4.2)
    event.drink_packages.create!(drink: drink, package: cask)

    expect(event.drink_packages.new(drink: drink, package: cask)).not_to be_valid
    expect(event.drink_packages.new(drink: drink, package: keg)).to be_valid
  end

  describe "#move" do
    it "swaps places with the next item up or down its section, past other brands" do
      urchin = list("Urchin", 6.1, can, st_mars, position: 1)
      list("Winter", 12.5, can, cider_hill, position: 2)
      list("Tripel", 8, can, st_mars, position: 3)

      urchin.move(:down)
      expect(side(Package.packaged)).to eq([[1, "Tripel"], [2, "Winter"], [3, "Urchin"]])

      urchin.reload.move(:up)
      expect(side(Package.packaged)).to eq([[1, "Urchin"], [2, "Winter"], [3, "Tripel"]])
    end

    it "stays put at either end of its section" do
      mild = list("Mild", 3.2, keg)
      porter = list("Porter", 5, keg)

      mild.reload.move(:up)
      porter.reload.move(:down)

      expect(side(Package.cooperage)).to eq([[1, "Mild"], [2, "Porter"]])
    end
  end

  describe "#move_brand" do
    it "moves a brand's drinks past the next brand's, keeping the house's drinks first" do
      list("Ludlow Lager", 5, can)
      list("Urchin", 6.1, can, st_mars)
      list("Tripel", 8, can, st_mars)
      winter = list("Winter", 12.5, can, cider_hill)

      winter.reload.move_brand(:up)
      expect(side(Package.packaged)).to eq([[1, "Ludlow Lager"], [2, "Winter"], [3, "Urchin"], [4, "Tripel"]])

      winter.reload.move_brand(:up)
      expect(side(Package.packaged)).to eq([[1, "Ludlow Lager"], [2, "Winter"], [3, "Urchin"], [4, "Tripel"]])

      winter.reload.move_brand(:down)
      expect(side(Package.packaged)).to eq([[1, "Ludlow Lager"], [2, "Urchin"], [3, "Tripel"], [4, "Winter"]])
    end

    it "leaves the house's own drinks where they are" do
      lager = list("Ludlow Lager", 5, can)
      list("Urchin", 6.1, can, st_mars)

      lager.reload.move_brand(:down)

      expect(side(Package.packaged)).to eq([[1, "Ludlow Lager"], [2, "Urchin"]])
    end
  end

  it "shows the drink's image unless it's switched off for the event" do
    drink = Drink.create!(name: "Orange Dinosaur", abv: 9)
    drink.image.attach(io: file_fixture("drink.png").open, filename: "drink.png")
    item = event.drink_packages.create!(drink: drink, package: keg)

    expect(item.image).to eq(drink.image)

    item.update!(show_image: false)
    expect(item.image).to be_nil
  end

  it "isn't kicked until marked" do
    item = list("Urchin", 6.1, can)

    expect(item).not_to be_kicked
    expect { item.update!(kicked: true) }.not_to change { item.reload.position }
  end

  it "keeps the emoji short" do
    item = event.drink_packages.new(drink: Drink.create!(name: "Old Powderhouse"), package: keg, emoji: "🔥")
    expect(item).to be_valid

    item.emoji = "🔥" * 17
    expect(item).not_to be_valid
  end

  it "closes the gap when an item is removed" do
    list("Mild", 3.2, keg)
    bitter = list("Bitter", 4.2, keg)
    list("Porter", 5, keg)

    bitter.destroy!

    expect(side(Package.cooperage)).to eq([[1, "Mild"], [2, "Porter"]])
  end
end
