require "rails_helper"

RSpec.describe Board do
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27), tagline: "Old Skool ’26") }
  let(:keg) { Keg.create!(volume: 5, unit: "gal") }
  let(:can) { Can.create!(volume: 0.44, unit: "liter") }
  let(:st_mars) { Brand.create!(name: "St. Mars of the Desert") }
  let(:russian_river) { Brand.create!(name: "Russian River") }

  def list(name, abv, package, brand = nil)
    event.drink_packages.create!(drink: Drink.create!(name: name, abv: abv, brand: brand), package: package)
  end

  def outline(sections)
    sections.map { |section| [section.title, section.items.map { |item| item.drink.name }] }
  end

  it "puts the house's drinks under the side's heading, then each brand in list order" do
    list("Mermaid Beacon", 4.8, keg)
    list("Pliny the Elder", 8, keg, russian_river)
    list("Gridlock IPA", 6.5, keg)
    list("Supplication", 7.75, can, russian_river)
    list("Babamama", 8.4, can, st_mars)
    list("Ludlow Lager", 5, can)
    list("Urchin", 6.1, can, st_mars)

    expect(outline(Board.new(event).left)).to eq([
      ["Tap List", ["Mermaid Beacon", "Gridlock IPA"]],
      ["Russian River", ["Pliny the Elder"]]
    ])
    expect(outline(Board.new(event).right)).to eq([
      ["Bottle List", ["Ludlow Lager"]],
      ["St. Mars of the Desert", ["Urchin", "Babamama"]],
      ["Russian River", ["Supplication"]]
    ])
  end

  it "leaves out a side's heading when all its drinks are branded" do
    list("Urchin", 6.1, can, st_mars)

    expect(outline(Board.new(event).right)).to eq([["St. Mars of the Desert", ["Urchin"]]])
  end

  it "shows nothing without an event" do
    board = Board.new(nil)

    expect([board.tagline, board.left, board.right]).to eq([nil, [], []])
  end
end
