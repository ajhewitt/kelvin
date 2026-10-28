require "rails_helper"

RSpec.describe "An event's list in the admin", type: :request do
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }
  let(:keg) { Keg.create!(volume: 5, unit: "gal") }
  let(:can) { Can.create!(volume: 0.44, unit: "liter") }
  let(:st_mars) { Brand.create!(name: "St. Mars of the Desert") }
  let(:cider_hill) { Brand.create!(name: "Cider Hill Cellars") }
  let(:list_path) { madmin_event_drink_packages_path(event) }

  before { log_in }

  def list(name, abv, package, brand: nil, **options)
    event.drink_packages.create!(drink: Drink.create!(name: name, abv: abv, brand: brand), package: package, **options)
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def names
    page.css(".list-item-name").map(&:text)
  end

  it "opens on the event the board is showing" do
    travel_to Time.utc(2026, 11, 20, 18) do
      Event.create!(name: "Last year", date: Date.new(2025, 11, 28))
      event

      get madmin_root_path
    end

    expect(response).to redirect_to(list_path)
  end

  it "starts with a new event when there are none" do
    get madmin_root_path

    expect(response).to redirect_to(new_madmin_event_path)
  end

  it "lays the list out like the board" do
    list("Mermaid Beacon", 4.8, keg, emoji: "🧜")
    list("Urchin", 6.1, can, brand: st_mars)
    list("Winter", 12.5, can, brand: cider_hill, kicked: true)

    get list_path

    expect(response).to have_http_status(:ok)
    expect(page.css(".list-side-title").map(&:text)).to eq(["Draft", "Bottles and cans", "Add a drink"])
    expect(page.css(".list-section-header h3").map(&:text)).to eq(["Tap List", "St. Mars of the Desert", "Cider Hill Cellars"])
    expect(names).to eq(["🧜 Mermaid Beacon", "Urchin", "Winter"])
    expect(page.css(".list-item-details").map { |details| details.text.squish }).to eq(["Keg 5 gal · 4.8%", "Can 440 ml · 6.1%", "Can 440 ml · 12.5%"])
    expect(page.css(".list-item--kicked .list-item-name").map(&:text)).to eq(["Winter"])
  end

  it "adds a drink in a package" do
    drink = Drink.create!(name: "Orange Dinosaur", abv: 8)

    post list_path, params: {drink_package: {drink_id: drink.id, package_id: keg.id, emoji: "🦖", show_image: "1"}}
    expect(response).to redirect_to(list_path)

    item = event.drink_packages.sole
    expect([item.drink, item.package, item.emoji, item.position]).to eq([drink, keg, "🦖", 1])
  end

  it "explains why a drink can't be added" do
    item = list("Orange Dinosaur", 8, keg)

    post list_path, params: {drink_package: {drink_id: item.drink_id, package_id: keg.id}}

    expect(response).to have_http_status(:unprocessable_content)
    expect(page.at_css(".alert-danger").text).to include("Drink is already listed in that package")
  end

  it "kicks a drink and brings it back" do
    item = list("Orange Dinosaur", 8, keg)

    patch madmin_event_drink_package_path(event, item), params: {drink_package: {kicked: true}}
    expect(response).to redirect_to(list_path)
    expect(item.reload).to be_kicked

    patch madmin_event_drink_package_path(event, item), params: {drink_package: {kicked: false}}
    expect(item.reload).not_to be_kicked
  end

  it "moves a drink up its section" do
    list("Mild", 3.2, keg)
    porter = list("Porter", 5, keg)

    patch move_madmin_event_drink_package_path(event, porter, direction: "up")
    expect(response).to redirect_to(list_path)

    follow_redirect!
    expect(names).to eq(["Porter", "Mild"])
  end

  it "moves a brand down its side" do
    urchin = list("Urchin", 6.1, can, brand: st_mars)
    list("Winter", 12.5, can, brand: cider_hill)

    patch move_brand_madmin_event_drink_package_path(event, urchin, direction: "down")
    follow_redirect!

    expect(page.css(".list-section-header h3").map(&:text)).to eq(["Cider Hill Cellars", "St. Mars of the Desert"])
  end

  it "changes a drink's emoji and image for the event" do
    item = list("Old Powderhouse", 12.2, keg)

    get edit_madmin_event_drink_package_path(event, item)
    expect(response).to have_http_status(:ok)

    patch madmin_event_drink_package_path(event, item), params: {drink_package: {emoji: "🔥", show_image: "0"}}
    expect(response).to redirect_to(list_path)
    expect([item.reload.emoji, item.show_image?]).to eq(["🔥", false])
  end

  it "takes a drink off the list" do
    item = list("Orange Dinosaur", 8, keg)

    delete madmin_event_drink_package_path(event, item)

    expect(response).to redirect_to(list_path)
    expect(DrinkPackage.exists?(item.id)).to be(false)
    expect(Drink.exists?(item.drink_id)).to be(true)
  end

  it "only changes items on the event in the address" do
    other = Event.create!(name: "Christmas", date: Date.new(2026, 12, 24))
    item = other.drink_packages.create!(drink: Drink.create!(name: "Kings Measure"), package: keg)

    patch madmin_event_drink_package_path(event, item), params: {drink_package: {kicked: true}}

    expect(response).to have_http_status(:not_found)
    expect(item.reload).not_to be_kicked
  end
end
