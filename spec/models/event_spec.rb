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

  it "starts on the Classic theme and takes only the board's own themes, easter eggs included" do
    expect(Event.new.theme).to eq("classic")
    expect(Event.new(name: "Party", date: Date.new(2026, 11, 14), theme: "public_house")).to be_valid
    expect(Event.new(name: "Party", date: Date.new(2026, 11, 14), theme: "trump")).to be_valid
    expect(Event.new(name: "Party", date: Date.new(2026, 11, 14), theme: "no_such_theme")).not_to be_valid
  end

  describe "#stats" do
    it "shows only ABV by default" do
      expect(Event.new.stats).to eq([:abv])
    end

    it "puts SRM before IBU before ABV" do
      expect(Event.new(show_ibu: true).stats).to eq([:ibu, :abv])
      expect(Event.new(show_srm: true, show_ibu: true).stats).to eq([:srm, :ibu, :abv])
      expect(Event.new(show_abv: false, show_ibu: true).stats).to eq([:ibu])
    end
  end

  it "won't delete the last event, so the board always has one to show" do
    only = event_on(Date.new(2026, 11, 14))

    expect(only.destroy).to be(false)
    expect(only.errors[:base]).to include("The last event can't be deleted")

    event_on(Date.new(2026, 12, 24))
    expect(only.destroy).to be_truthy
  end

  it "unlinks its serving session when deleted, keeping the session and its logs" do
    event_on(Date.new(2026, 12, 24))
    event = event_on(Date.new(2026, 11, 27))
    serving = Session.create!(configuration: Configuration.create!(name: "Service Mode", slug: "service"), event: event)

    event.destroy!

    expect(serving.reload.event).to be_nil
  end
end
