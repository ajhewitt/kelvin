require "rails_helper"

RSpec.describe "Sessions in the admin", type: :request do
  let!(:service) { Configuration.create!(name: "Service Mode", slug: "service") }
  let(:ferment) { Configuration.create!(name: "Fermentation Guard", slug: "ferment") }
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }

  before { log_in }

  def page
    Nokogiri::HTML(response.body)
  end

  def form_fields
    page.css("form [name^='session[']").map { |field| field["name"] }
  end

  it "edits a session's status and times on its form" do
    get new_madmin_session_path
    expect(form_fields).to eq(["session[configuration_id]", "session[status]", "session[started_at]", "session[ended_at]"])

    post madmin_sessions_path, params: {session: {configuration_id: ferment.id, status: "active", started_at: "2026-11-27T18:00"}}
    expect([Session.last.status, Session.last.started_at]).to eq(["active", Time.zone.parse("2026-11-27 18:00")])
  end

  it "offers an event only to a serving session" do
    serving = Session.create!(configuration: service)

    get edit_madmin_session_path(serving)
    expect(form_fields).to include("session[event_id]")

    patch madmin_session_path(serving), params: {session: {event_id: event.id}}
    expect(serving.reload.event).to eq(event)

    get edit_madmin_session_path(Session.create!(configuration: ferment))
    expect(form_fields).not_to include("session[event_id]")
  end

  it "leaves starting, stopping and settings off a session's page" do
    session = Session.create!(configuration: service)

    get madmin_session_path(session)

    expect(page.css("main > div button").map { |button| button.text.strip }).to eq(["Delete"])
    expect(page.css("th").map { |label| label.text.strip }).not_to include("Settings")
  end

  it "shows each session's event in the list" do
    Session.create!(configuration: service, event: event)

    get madmin_sessions_path

    expect(page.css("tbody tr td").map { |cell| cell.text.strip }.first(3)).to eq(["Service Mode", "Black Friday", "pending"])
  end

  describe "serving, from the event's list" do
    let(:list) { madmin_event_drink_packages_path(event) }

    # The list's serving panel, a line of text to a row, buttons included
    def serving_panel
      page.css(".list-serving-row").map { |row| row.text.squish }
    end

    it "starts serving, adding the event's serving session at 38°F" do
      get list
      expect(serving_panel).to eq(["Serving Not started Start"])

      travel_to(Time.utc(2026, 11, 27, 18)) { post madmin_event_serving_path(event) }

      serving = event.reload.serving_session
      expect([serving.configuration, serving.status, serving.started_at]).to eq([service, "active", Time.utc(2026, 11, 27, 18)])
      expect(response).to redirect_to(list)
      follow_redirect!
      expect(serving_panel).to eq(["Serving Active Stop Service Mode ##{serving.id}", "Draft temp − 38°F + No reading yet"])
    end

    it "runs the session with start and stop, until it's complete" do
      serving = Session.create!(configuration: service, event: event)

      get list
      expect(serving_panel.first).to eq("Serving Pending Start Service Mode ##{serving.id}")

      [[:start, "pending", "Active Stop"], [:stop, "active", "Inactive Start Stop"], [:stop, "inactive", "Complete"]].each do |button, from, panel|
        patch public_send(:"#{button}_madmin_event_serving_path", event), params: {from: from}
        expect(response).to redirect_to(list)
        follow_redirect!
        expect(serving_panel.first).to eq("Serving #{panel} Service Mode ##{serving.id}")
      end
      expect(serving_panel.last).to eq("Draft temp 38°F No reading yet")
    end

    it "asks before the stop that completes the session" do
      serving = Session.create!(configuration: service, event: event)
      serving.start

      get list
      expect(page.at_css("form[action$='/serving/stop']")["data-turbo-confirm"]).to be_nil

      serving.stop
      get list
      expect(page.at_css("form[action$='/serving/stop']")["data-turbo-confirm"]).to eq("Complete this session? It can't be started again.")
    end

    it "won't complete the session on a double click of stop" do
      serving = Session.create!(configuration: service, event: event)
      serving.start

      2.times { patch stop_madmin_event_serving_path(event), params: {from: "active"} }

      expect(serving.reload).to be_inactive
      follow_redirect!
      expect(page.at_css(".alert").text).to include("Serving is already inactive.")
    end

    it "turns the draft temperature up and down" do
      Session.create!(configuration: service, event: event)

      %w[up up down up].each { |direction| patch draft_temp_madmin_event_serving_path(event, direction: direction) }

      expect(response).to redirect_to(list)
      follow_redirect!
      expect(serving_panel.last).to eq("Draft temp − 40°F + No reading yet")
    end

    it "shows the draft temperature's latest reading, with its time" do
      serving = Session.create!(configuration: service, event: event)
      serving.start
      sensor = OneWireSensor.create!(name: "Draft Temp", slug: "draft_temp")
      serving.sensor_readings.create!(sensor: sensor, reading_value: 39.24, recorded_at: Time.utc(2026, 11, 27, 18, 5))

      Time.use_zone("America/New_York") { get list }

      expect(serving_panel.last).to eq("Draft temp − 38°F + Reading 39.2°F at 27 Nov 13:05")
    end

    it "won't add a second serving session to the event" do
      2.times { post madmin_event_serving_path(event) }

      expect(Session.where(event: event).count).to eq(1)
      follow_redirect!
      expect(page.at_css(".alert").text).to include("Black Friday already has a serving session.")
    end

    it "says what's missing when there's no configuration to serve from" do
      service.destroy!

      get list

      expect(serving_panel).to eq([%(Serving Add a configuration with the slug "service" to serve from)])
    end
  end
end
