require "rails_helper"

RSpec.describe "Picking an event's theme in the admin", type: :request do
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }

  before { log_in }

  def page
    Nokogiri::HTML(response.body)
  end

  it "previews every theme on the event's board" do
    get themes_madmin_event_path(event)

    expect(page.css(".theme-card iframe").map { |frame| frame["src"] }).to eq(Event::THEMES.keys.map { |theme| event_board_path(event, theme: theme) })
    expect(page.at_css(".theme-card--current strong").text).to eq("Classic")
  end

  it "picks a theme and stays on the previews" do
    patch theme_madmin_event_path(event), params: {theme: "tudor"}

    expect(response).to redirect_to(themes_madmin_event_path(event))
    expect(event.reload.theme).to eq("tudor")
  end

  it "turns down a theme the board doesn't have" do
    patch theme_madmin_event_path(event), params: {theme: "disco"}

    expect(event.reload.theme).to eq("classic")
    expect(flash[:alert]).to be_present
  end

  it "offers every theme on the event's form" do
    get edit_madmin_event_path(event)

    expect(page.css("select#event_theme option").map { |option| option["value"] }).to eq(Event::THEMES.keys)
  end
end
