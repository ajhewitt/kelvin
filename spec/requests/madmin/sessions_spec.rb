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

  # A row of a session's page as a line of text, buttons included
  def row(label)
    page.css("tr").find { |tr| tr.at_css("th").text.strip == label }.at_css("td").text.squish
  end

  describe "a session's page" do
    it "runs the session with start and stop, which stamp its times" do
      session = Session.create!(configuration: ferment)
      started = Time.utc(2026, 11, 27, 18)

      get madmin_session_path(session)
      expect(row("Status")).to eq("Pending Start")

      [[:start, "pending", "Active Stop", 0], [:stop, "active", "Inactive Start Stop", 3], [:stop, "inactive", "Complete", 4]].each do |button, from, status, hours|
        travel_to(started + hours.hours) { patch public_send(:"#{button}_madmin_session_path", session), params: {from: from} }
        expect(response).to redirect_to(madmin_session_path(session))
        follow_redirect!
        expect(row("Status")).to eq(status)
      end
      expect([session.reload.started_at, session.ended_at]).to eq([started, started + 4.hours])
    end

    it "asks before the stop that completes a session" do
      session = Session.create!(configuration: ferment)
      session.start

      get madmin_session_path(session)
      expect(page.at_css("form[action$='/stop']")["data-turbo-confirm"]).to be_nil

      session.stop
      get madmin_session_path(session)
      expect(page.at_css("form[action$='/stop']")["data-turbo-confirm"]).to eq("Complete this session? It can't be started again.")
    end

    it "won't complete a session on a double click of stop" do
      session = Session.create!(configuration: ferment)
      session.start

      2.times { patch stop_madmin_session_path(session), params: {from: "active"} }

      expect(session.reload).to be_inactive
      follow_redirect!
      expect(page.at_css(".alert").text).to include("Fermentation Guard ##{session.id} is already inactive.")
    end

    it "shows the settings its configuration gives it, with their buttons" do
      get madmin_session_path(Session.create!(configuration: service))
      expect(row("Settings")).to eq("Draft temp − 38°F + No reading yet")

      get madmin_session_path(Session.create!(configuration: ferment))
      expect(row("Settings")).to eq("None")
    end

    it "turns a setting up and down, coming back to the page" do
      session = Session.create!(configuration: service)

      %w[up up down up].each do |direction|
        patch nudge_madmin_session_path(session, key: "draft_temp", direction: direction), headers: {"HTTP_REFERER" => madmin_session_url(session)}
      end

      expect(response).to redirect_to(madmin_session_url(session))
      follow_redirect!
      expect(row("Settings")).to eq("Draft temp − 40°F + No reading yet")
    end

    it "leaves a complete session's settings as they ended" do
      session = Session.create!(configuration: service)
      session.start
      2.times { session.stop }

      patch nudge_madmin_session_path(session, key: "draft_temp", direction: "up")

      expect(session.draft_temp.value).to eq(38.0)
      follow_redirect!
      expect(page.at_css(".alert").text).to include("Service Mode ##{session.id} is complete.")
    end
  end

  describe "the session form" do
    it "leaves the status and times to the buttons" do
      get new_madmin_session_path
      expect(form_fields).to eq(["session[configuration_id]"])

      post madmin_sessions_path, params: {session: {configuration_id: ferment.id, status: "complete", started_at: "2026-11-27T18:00"}}
      expect([Session.last.status, Session.last.started_at]).to eq(["pending", nil])
    end

    it "offers an event only to a serving session" do
      serving = Session.create!(configuration: service)

      get edit_madmin_session_path(serving)
      expect(form_fields).to eq(["session[configuration_id]", "session[event_id]"])

      patch madmin_session_path(serving), params: {session: {event_id: event.id}}
      expect(serving.reload.event).to eq(event)

      get edit_madmin_session_path(Session.create!(configuration: ferment))
      expect(form_fields).to eq(["session[configuration_id]"])
    end
  end

  it "shows each session's event and status in the list" do
    Session.create!(configuration: service, event: event).start

    get madmin_sessions_path

    expect(page.css("tbody tr td").map { |cell| cell.text.strip }.first(3)).to eq(["Service Mode", "Black Friday", "Active"])
  end

  describe "serving, from the event's list" do
    let(:list) { madmin_event_drink_packages_url(event) }

    # The list's serving panel, a line of text to a row, buttons included
    def serving_panel
      page.css(".list-serving .session-controls").map { |row| row.text.squish }
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

    it "runs serving with the session's own buttons, coming back to the list" do
      serving = Session.create!(configuration: service, event: event)

      get list
      expect(serving_panel.first).to eq("Serving Pending Start Service Mode ##{serving.id}")

      [[:start, "pending", "Active Stop"], [:stop, "active", "Inactive Start Stop"], [:stop, "inactive", "Complete"]].each do |button, from, panel|
        patch public_send(:"#{button}_madmin_session_path", serving), params: {from: from}, headers: {"HTTP_REFERER" => list}
        expect(response).to redirect_to(list)
        follow_redirect!
        expect(serving_panel.first).to eq("Serving #{panel} Service Mode ##{serving.id}")
      end
      expect(serving_panel.last).to eq("Draft temp 38°F No reading yet")
    end

    it "turns the draft temperature up and down, coming back to the list" do
      serving = Session.create!(configuration: service, event: event)

      %w[up up down up].each do |direction|
        patch nudge_madmin_session_path(serving, key: "draft_temp", direction: direction), headers: {"HTTP_REFERER" => list}
      end

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
