require "rails_helper"

RSpec.describe Brand, type: :model do
  it "requires a unique name" do
    Brand.create!(name: "St. Mars of the Desert")

    expect(Brand.new(name: "St. Mars of the Desert")).not_to be_valid
    expect(Brand.new).not_to be_valid
  end

  it "takes its drinks off every event's list when deleted" do
    brand = Brand.create!(name: "Cider Hill Cellars")
    drink = brand.drinks.create!(name: "Winter", abv: 12.5)
    event = Event.create!(name: "Party", date: Date.new(2026, 11, 14))
    event.drink_packages.create!(drink: drink, package: Can.create!(volume: 0.125, unit: "gal"))

    brand.destroy!

    expect(Drink.exists?(drink.id)).to be(false)
    expect(DrinkPackage.exists?(event_id: event.id)).to be(false)
  end
end
