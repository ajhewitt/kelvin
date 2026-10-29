require "rails_helper"

RSpec.describe Session, type: :model do
  let(:service) { Configuration.create!(name: "Service Mode", slug: "service") }
  let(:ferment) { Configuration.create!(name: "Fermentation Guard", slug: "ferment") }
  let(:event) { Event.create!(name: "Black Friday", date: Date.new(2026, 11, 27)) }
  let(:session) { Session.create!(configuration: service) }

  it "is pending to start with, with no start or end time" do
    expect([session.status, session.started_at, session.ended_at]).to eq(["pending", nil, nil])
  end

  it "gives a serving session a draft temperature of 38°F to start" do
    expect(session.settings.pluck(:key, :value)).to eq([["draft_temp", 38.0]])
    expect(Session.create!(configuration: ferment).settings).to be_empty
  end

  it "goes active on start and inactive on stop, and completes when stopped while inactive" do
    statuses = %i[start stop start stop stop].map { |button| session.public_send(button) && session.reload.status }

    expect(statuses).to eq(%w[active inactive active inactive complete])
  end

  it "stamps the start time as it leaves pending and the end time as it completes" do
    started = Time.utc(2026, 11, 27, 18)

    travel_to(started) { session.start }
    travel_to(started + 3.hours) { session.stop }
    travel_to(started + 4.hours) { session.start }
    expect([session.reload.started_at, session.ended_at]).to eq([started, nil])

    travel_to(started + 6.hours) { 2.times { session.stop } }
    expect([session.reload.started_at, session.ended_at]).to eq([started, started + 6.hours])
  end

  it "stamps the start time whatever it leaves pending for" do
    travel_to(Time.utc(2026, 11, 27, 18)) { session.update!(status: :complete) }

    expect([session.reload.started_at, session.ended_at]).to all(eq(Time.utc(2026, 11, 27, 18)))
  end

  it "can't be stopped before it's started" do
    expect(session.stop).to be(false)
    expect(session.reload).to be_pending
  end

  it "can't go back to pending once stopped" do
    session.start
    session.stop

    expect(session.update(status: :pending)).to be(false)
  end

  it "can't be started again once complete" do
    session.start
    2.times { session.stop }

    expect([session.start, session.stop, session.update(status: :active)]).to eq([false, false, false])
    expect(session.reload).to be_complete
  end

  it "can be for an event when it's a serving session" do
    brewing = Session.new(configuration: ferment, event: event)

    expect(Session.new(configuration: service, event: event)).to be_valid
    expect(brewing).not_to be_valid
    expect(brewing.errors.full_messages).to eq(["Event is only for serving sessions"])
  end

  it "allows one session to an event" do
    Session.create!(configuration: service, event: event)
    second = Session.new(configuration: service, event: event)

    expect(second).not_to be_valid
    expect(second.errors.full_messages).to eq(["Event already has a serving session"])
  end
end
