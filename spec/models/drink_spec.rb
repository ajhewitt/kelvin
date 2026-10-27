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
end
