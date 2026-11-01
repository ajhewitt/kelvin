require "rails_helper"

RSpec.describe "Picking an event's theme in the admin", type: :request do
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }

  before { log_in }

  def page
    Nokogiri::HTML(response.body)
  end

  # The previews' themes, from their cards' board links, the hidden ones or the rest
  def previews(hidden:)
    page.css(".theme-card").select { |card| card.key?("hidden") == hidden }.map { |card| Rack::Utils.parse_query(URI(card.at_css("iframe")["src"]).query)["theme"] }
  end

  it "previews every theme on the event's board, with the easter eggs hidden" do
    get themes_madmin_event_path(event)

    expect(previews(hidden: false)).to eq(Event::THEMES.keys)
    expect(previews(hidden: true)).to eq(Event::EASTER_EGGS.keys)
    expect(page.at_css(".theme-card--current strong").text).to eq("Classic")
    expect(page.css("script").map(&:text).join).to include("arrowup arrowup arrowdown arrowdown", "[data-egg-taps]")
  end

  it "picks an easter egg once it's found, and shows it from then on" do
    patch theme_madmin_event_path(event), params: {theme: "trump"}
    expect(event.reload.theme).to eq("trump")

    follow_redirect!
    expect(previews(hidden: true)).to be_empty
    expect(page.at_css(".theme-card--current strong").text).to eq("Trump")
  end

  it "picks a theme and stays on the previews" do
    patch theme_madmin_event_path(event), params: {theme: "tudor"}

    expect(response).to redirect_to(themes_madmin_event_path(event))
    expect(event.reload.theme).to eq("tudor")
  end

  it "turns down a theme the board doesn't have" do
    patch theme_madmin_event_path(event), params: {theme: "no_such_theme"}

    expect(event.reload.theme).to eq("classic")
    expect(flash[:alert]).to be_present
  end

  it "offers every theme on the event's form" do
    get edit_madmin_event_path(event)

    expect(page.css("select#event_theme option").map { |option| option["value"] }).to eq(Event::THEMES.keys)
  end

  it "keeps an easter egg the event uses on its form, so saving the form keeps it" do
    event.update!(theme: "trump")

    get edit_madmin_event_path(event)

    expect(page.css("select#event_theme option").map { |option| option["value"] }).to eq(Event::THEMES.keys + ["trump"])
    expect(page.at_css("select#event_theme option[selected]")["value"]).to eq("trump")
  end
end
