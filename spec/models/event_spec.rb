require "rails_helper"

RSpec.describe Event, type: :model do
  let(:eastern) { ActiveSupport::TimeZone["America/New_York"] }

  def event_on(date)
    Event.create!(name: "Event on #{date}", date: date)
  end

  it "requires a name and a date, with one event per date" do
    event_on(Date.new(2026, 11, 14))

    expect(Event.new(name: "Again", date: Date.new(2026, 11, 14))).not_to be_valid
    expect(Event.new(date: Date.new(2026, 11, 15))).not_to be_valid
    expect(Event.new(name: "Undated")).not_to be_valid
  end

  describe ".business_date" do
    it "changes at noon UTC, which is 8am in summer" do
      expect(Event.business_date(eastern.local(2026, 7, 4, 7, 59))).to eq(Date.new(2026, 7, 3))
      expect(Event.business_date(eastern.local(2026, 7, 4, 8, 0))).to eq(Date.new(2026, 7, 4))
    end

    it "changes at noon UTC, which is 7am in winter" do
      expect(Event.business_date(eastern.local(2026, 12, 24, 6, 59))).to eq(Date.new(2026, 12, 23))
      expect(Event.business_date(eastern.local(2026, 12, 24, 7, 0))).to eq(Date.new(2026, 12, 24))
    end
  end

  describe ".current" do
    let!(:past) { event_on(Date.new(2026, 10, 3)) }
    let!(:party) { event_on(Date.new(2026, 11, 14)) }
    let!(:christmas) { event_on(Date.new(2026, 12, 24)) }

    it "is the next event coming up" do
      expect(Event.current(eastern.local(2026, 10, 27, 20, 0))).to eq(party)
    end

    it "stays on an event past midnight until the next morning" do
      expect(Event.current(eastern.local(2026, 11, 14, 20, 0))).to eq(party)
      expect(Event.current(eastern.local(2026, 11, 15, 6, 59))).to eq(party)
      expect(Event.current(eastern.local(2026, 11, 15, 7, 0))).to eq(christmas)
    end

    it "falls back to the most recent event when nothing is coming up" do
      expect(Event.current(eastern.local(2027, 1, 10, 20, 0))).to eq(christmas)
    end
  end

  it "won't delete the last event, so the board always has one to show" do
    only = event_on(Date.new(2026, 11, 14))

    expect(only.destroy).to be(false)
    expect(only.errors[:base]).to include("The last event can't be deleted")

    event_on(Date.new(2026, 12, 24))
    expect(only.destroy).to be_truthy
  end
end
