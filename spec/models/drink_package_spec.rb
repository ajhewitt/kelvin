require "rails_helper"

RSpec.describe DrinkPackage, type: :model do
  let(:event) { Event.create!(name: "Party", date: Date.new(2026, 11, 14)) }
  let(:keg) { Keg.create!(volume: 5, unit: "gal") }
  let(:cask) { Cask.create!(volume: 4.5, unit: "imp_gal") }
  let(:can) { Can.create!(volume: 0.125, unit: "gal") }

  def list(name, abv, package)
    event.drink_packages.create!(drink: Drink.create!(name: name, abv: abv), package: package)
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

  it "keeps drinks without an ABV at the end of their side" do
    list("Mystery", nil, keg)
    list("Porter", 5, keg)
    list("Mild", 3.2, keg)

    expect(side(Package.cooperage)).to eq([[1, "Mild"], [2, "Porter"], [3, "Mystery"]])
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

  it "moves an item and renumbers its side" do
    list("Mild", 3.2, keg)
    list("Bitter", 4.2, keg)
    porter = list("Porter", 5, keg)

    porter.move_to(1)

    expect(side(Package.cooperage)).to eq([[1, "Porter"], [2, "Mild"], [3, "Bitter"]])
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
