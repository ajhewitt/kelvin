require "rails_helper"

RSpec.describe "Board", type: :request do
  let(:keg) { Keg.create!(volume: 5, unit: "gal") }
  let(:bottle) { Bottle.create!(volume: 0.66, unit: "liter") }
  let(:st_mars) { Brand.create!(name: "St. Mars of the Desert") }
  let(:wpe_2_44) { "Mozilla/5.0 (X11; Linux aarch64) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15" }

  def list(event, name, abv, package, brand: nil, **options)
    event.drink_packages.create!(drink: Drink.create!(name: name, abv: abv, brand: brand), package: package, **options)
  end

  def page
    Nokogiri::HTML(response.body)
  end

  def stylesheets
    page.css("link[rel=stylesheet]").map { |link| link["href"] }
  end

  it "shows the current event's list on the root page" do
    last_year = Event.create!(name: "A Decade in the Making", date: Date.new(2025, 11, 28), tagline: "A Decade in the Making ’25")
    this_year = Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27), tagline: "Old Skool ’26")
    list(last_year, "Harvey's Mild", 3.2, keg)
    list(this_year, "Mermaid Beacon", 4.8, keg)
    list(this_year, "Urchin", 6.1, bottle, brand: st_mars)

    travel_to Time.utc(2026, 11, 20, 18) do
      get root_path
    end

    expect(response).to have_http_status(:ok)
    expect(page.at_css(".board-tagline").text.strip).to eq("Old Skool ’26")
    expect(page.css(".board-section-title").map(&:text)).to eq(["Tap List", "St. Mars of the Desert"])
    expect(page.css(".board-item-name").map(&:text)).to eq(["Mermaid Beacon", "Urchin (660)"])
    expect(page.css(".board-item-stat").map(&:text)).to eq(["4.8%", "6.1%"])
    expect(response.body).not_to include("Harvey's Mild")
  end

  it "serves the board to the kiosk's older WPE WebKit" do
    Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))

    get root_path, headers: {"User-Agent" => wpe_2_44}

    expect(response).to have_http_status(:ok)
  end

  it "previews any event's board" do
    past = Event.create!(name: "Black Friday Blowout", date: Date.new(2023, 11, 24), tagline: "Black Friday ’23 Blowout")
    Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))

    get event_board_path(past)

    expect(page.at_css(".board-tagline").text.strip).to eq("Black Friday ’23 Blowout")
  end

  it "shows the image and emoji chosen for the event" do
    event = Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))
    dinosaur = list(event, "Orange Dinosaur", 8, keg)
    dinosaur.drink.image.attach(io: file_fixture("drink.png").open, filename: "drink.png")
    list(event, "Old Powderhouse", 12.2, keg, emoji: "🔥")

    get root_path

    expect(page.css("img.board-item-image").size).to eq(1)
    expect(page.at_css(".board-item-emoji").text.strip).to eq("🔥")
  end

  it "shows the stats turned on for the event, SRM then IBU then ABV, skipping missing values" do
    event = Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27), show_ibu: true, show_srm: true)
    list(event, "India Wharf Pale Ale", 4.2, keg)
    event.drink_packages.create!(drink: Drink.create!(name: "Gridlock IPA", abv: 6.5, ibu: 76, srm: 12.5), package: keg)

    get root_path

    stats = page.css(".board-item-stats").map { |row| row.css(".board-item-stat").map { |stat| stat.text.strip } }
    expect(stats).to eq([["", "", "4.2%"], ["12.5 SRM", "76 IBU", "6.5%"]])
  end

  it "keeps kicked items on the board, crossed out" do
    event = Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))
    list(event, "Urchin", 6.1, bottle, brand: st_mars, kicked: true)
    list(event, "Mermaid Beacon", 4.8, keg)

    get root_path

    expect(page.css(".board-item-name").map(&:text)).to contain_exactly("Urchin (660)", "Mermaid Beacon")
    expect(page.css(".board-item--kicked .board-item-name").map(&:text)).to eq(["Urchin (660)"])
  end

  it "dresses the board in the event's theme" do
    Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27), theme: "public_house")

    get root_path

    expect(stylesheets).to contain_exactly(a_string_matching(%r{/board-\w+\.css}), a_string_matching(%r{/themes/public_house-\w+\.css}))
  end

  it "needs only the board's own stylesheet for the Classic theme" do
    Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))

    get root_path

    expect(stylesheets).to contain_exactly(a_string_matching(%r{/board-\w+\.css}))
  end

  it "previews any theme without reloading every minute" do
    event = Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27))

    get event_board_path(event, theme: "neon")
    expect(stylesheets).to include(a_string_matching(%r{/themes/neon-\w+\.css}))
    expect(page.at_css("meta[http-equiv=refresh]")).to be_nil

    get event_board_path(event, theme: "../board")
    expect(stylesheets.size).to eq(1)
    expect(page.at_css("meta[http-equiv=refresh]")).to be_present
  end

  it "still renders before any event exists" do
    get root_path

    expect(response).to have_http_status(:ok)
    expect(page.at_css(".board-title").text).to eq("The Ludlow Park")
  end
end
