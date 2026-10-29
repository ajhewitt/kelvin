require "rails_helper"

RSpec.describe "Starting and stopping sessions in the admin", type: :request do
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

  it "starts serving from the event's page, adding its serving session" do
    get madmin_event_path(event)
    expect(row("Serving session")).to eq([["Not started"], ["Start"]])

    travel_to(Time.utc(2026, 11, 27, 18)) { post serve_madmin_event_path(event) }

    serving = event.reload.serving_session
    expect([serving.configuration, serving.status, serving.started_at]).to eq([service, "active", Time.utc(2026, 11, 27, 18)])
    follow_redirect!
    expect(row("Serving session")).to eq([["Active"], ["Stop"]])
    expect(page.at_css("td a[href='#{madmin_session_path(serving)}']").text).to eq("Service Mode ##{serving.id}")
  end

  it "stops and starts the event's session from the event's page" do
    serving = Session.create!(configuration: service, event: event)
    serving.start

    patch stop_madmin_session_path(serving), params: {from: "active"}, headers: {"HTTP_REFERER" => madmin_event_url(event)}

    expect(response).to redirect_to(madmin_event_url(event))
    follow_redirect!
    expect(row("Serving session")).to eq([["Inactive"], ["Start", "Stop"]])
  end

  it "won't add a second serving session to an event" do
    2.times { post serve_madmin_event_path(event) }

    expect(Session.where(event: event).count).to eq(1)
    follow_redirect!
    expect(page.at_css(".alert").text).to include("Black Friday already has a serving session.")
  end

  it "says what's missing when there's no configuration to serve from" do
    service.destroy!

    get madmin_event_path(event)

    expect(row("Serving session")).to eq([[%(Add a configuration with the slug "service" to serve from)], []])
  end

  it "shows each session's event and status in the list" do
    Session.create!(configuration: service, event: event).start

    get madmin_sessions_path

    expect(page.css("tbody tr td").map { |cell| cell.text.strip }.first(3)).to eq(["Service Mode", "Black Friday", "Active"])
  end
end
