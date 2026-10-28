require "rails_helper"

RSpec.describe Drink, type: :model do
  it "doesn't need a brand, since unbranded drinks are the house's own" do
    expect(Drink.new(name: "Harvey's Mild")).to be_valid
  end

  it "requires a name" do
    expect(Drink.new(abv: 3.2)).not_to be_valid
  end

  it "keeps ABV, IBU and SRM optional but in range" do
    expect(Drink.new(name: "Mild", abv: 3.2, ibu: 20, srm: 18.5)).to be_valid
    expect(Drink.new(name: "Mild", abv: 101)).not_to be_valid
    expect(Drink.new(name: "Mild", ibu: 12.5)).not_to be_valid
    expect(Drink.new(name: "Mild", srm: -1)).not_to be_valid
  end

  it "shows its ABV alongside its name, to tell brews apart" do
    expect(Drink.new(name: "Orange Dinosaur", abv: 8).to_s).to eq("Orange Dinosaur (8%)")
    expect(Drink.new(name: "Old Powderhouse", abv: 12.2).to_s).to eq("Old Powderhouse (12.2%)")
    expect(Drink.new(name: "Mystery").to_s).to eq("Mystery")
  end

  it "only takes a picture as its image" do
    drink = Drink.new(name: "Orange Dinosaur")

    drink.image.attach(io: file_fixture("drink.png").open, filename: "drink.png")
    expect(drink).to be_valid

    drink.image.attach(io: StringIO.new("not a picture"), filename: "notes.txt")
    expect(drink).not_to be_valid
  end

  it "can resize its image for the board" do
    drink = Drink.create!(name: "Orange Dinosaur")
    drink.image.attach(io: file_fixture("drink.png").open, filename: "drink.png")

    expect { drink.image.variant(:thumb).processed }.not_to raise_error
  end
end
