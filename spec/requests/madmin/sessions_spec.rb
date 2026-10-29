require "rails_helper"

RSpec.describe "Running sessions in the admin", type: :request do
  let!(:service) { Configuration.create!(name: "Service Mode", slug: "service") }
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }

  before { log_in }

  def page
    Nokogiri::HTML(response.body)
  end

  # A row of a record page's table, as its text and its buttons
  def row(label)
    cell = page.css("tr").find { |tr| tr.at_css("th").text.strip == label }.at_css("td")
    [cell.css("span").map { |span| span.text.strip }, cell.css("button").map { |button| button.text.strip }]
  end

  it "runs a session from its page with start and stop" do
    session = Session.create!(configuration: service)

    get madmin_session_path(session)
    expect(row("Status")).to eq([["Pending"], ["Start"]])

    [[:start, "pending", ["Active"], ["Stop"]], [:stop, "active", ["Inactive"], ["Start", "Stop"]], [:stop, "inactive", ["Complete"], []]]
      .each do |button, from, status, buttons|
        patch "/madmin/sessions/#{session.id}/#{button}", params: {from: from}
        follow_redirect!
        expect(row("Status")).to eq([status, buttons])
      end
  end

  it "asks before a stop that completes a session" do
    session = Session.create!(configuration: service)
    session.start

    get madmin_session_path(session)
    expect(page.at_css("form[action$='/stop']")["data-turbo-confirm"]).to be_nil

    session.stop
    get madmin_session_path(session)
    expect(page.at_css("form[action$='/stop']")["data-turbo-confirm"]).to eq("Complete this session? It can't be started again.")
  end

  it "won't complete a session on a double click of stop" do
    session = Session.create!(configuration: service)
    session.start

    2.times { patch stop_madmin_session_path(session), params: {from: "active"} }

    expect(session.reload).to be_inactive
    follow_redirect!
    expect(page.at_css(".alert").text).to include("Service Mode ##{session.id} is already inactive.")
  end

  it "leaves the status and times to the buttons" do
    get new_madmin_session_path

    expect(page.css("form [name^='session[']").map { |field| field["name"] }).to eq(["session[configuration_id]", "session[event_id]"])

    post madmin_sessions_path, params: {session: {configuration_id: service.id, status: "complete", started_at: "2026-11-27 18:00"}}
    expect([Session.last.status, Session.last.started_at]).to eq(["pending", nil])
  end

  it "shows a session's settings on its page" do
    session = Session.create!(configuration: service)

    get madmin_session_path(session)

    expect(page.at_css("a[href='#{madmin_setting_path(session.draft_temp)}']").text).to eq("draft_temp: 38.0")
  end

  it "shows each session's event and status in the list" do
    Session.create!(configuration: service, event: event).start

    get madmin_sessions_path

    expect(page.css("tbody tr td").map { |cell| cell.text.strip }.first(3)).to eq(["Service Mode", "Black Friday", "Active"])
  end

  describe "on the event's list" do
    let(:list) { madmin_event_drink_packages_url(event) }

    # The list's serving panel, a line of text to a row, buttons included
    def serving_panel
      page.css(".list-serving-row").map { |row| row.text.squish }
    end

    it "starts serving, adding the event's serving session at 38°F" do
      get list
      expect(serving_panel).to eq(["Serving Not started Start"])

      travel_to(Time.utc(2026, 11, 27, 18)) { post serve_madmin_event_path(event) }

      serving = event.reload.serving_session
      expect([serving.configuration, serving.status, serving.started_at]).to eq([service, "active", Time.utc(2026, 11, 27, 18)])
      expect(response).to redirect_to(list)
      follow_redirect!
      expect(serving_panel).to eq(["Serving Active Stop Service Mode ##{serving.id}", "Draft temp − 38°F + No reading yet"])
    end

    it "stops and starts the event's session, coming back to the list" do
      serving = Session.create!(configuration: service, event: event)
      serving.start

      patch stop_madmin_session_path(serving), params: {from: "active"}, headers: {"HTTP_REFERER" => list}

      expect(response).to redirect_to(list)
      follow_redirect!
      expect(serving_panel.first).to eq("Serving Inactive Start Stop Service Mode ##{serving.id}")
    end

    it "turns the draft temperature up and down" do
      serving = Session.create!(configuration: service, event: event)

      %w[up up down up].each { |direction| patch nudge_madmin_setting_path(serving.draft_temp, direction: direction), headers: {"HTTP_REFERER" => list} }

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

    it "keeps the temperature but not its buttons once serving is complete" do
      serving = Session.create!(configuration: service, event: event)
      serving.start
      2.times { serving.stop }

      get list

      expect(serving_panel).to eq(["Serving Complete Service Mode ##{serving.id}", "Draft temp 38°F No reading yet"])
    end

    it "won't add a second serving session to the event" do
      2.times { post serve_madmin_event_path(event) }

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
