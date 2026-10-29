require "rails_helper"

RSpec.describe Setting, type: :model do
  let(:service) { Configuration.create!(name: "Service Mode", slug: "service") }
  let(:session) { Session.create!(configuration: service) }
  let(:draft_temp) { session.draft_temp }
  let(:sensor) { OneWireSensor.create!(name: "Draft Temp", slug: "draft_temp") }

  def read(sensor, value, session: self.session)
    session.sensor_readings.create!(sensor: sensor, reading_value: value, recorded_at: Time.current)
  end

  it "holds one value for each key in a session" do
    expect(session.settings.new(key: "draft_temp", value: 40)).not_to be_valid
    expect(session.settings.new(key: "cask_temp", value: 52)).to be_valid
  end

  it "reads the latest reading in its session from the sensor named by its key" do
    glycol = OneWireSensor.create!(name: "Glycol Reservoir Temp", slug: "glycol_temp")
    read(sensor, 37.5)
    read(sensor, 38.2)
    read(glycol, 28.0)
    read(sensor, 45.0, session: Session.create!(configuration: service))

    expect(draft_temp.reading.reading_value).to eq(38.2)
  end

  it "has no reading until its sensor reads in its session" do
    expect(draft_temp.reading).to be_nil

    sensor
    expect(draft_temp.reading).to be_nil
  end

  it "moves a degree a press" do
    %i[up up down up].each { |direction| draft_temp.nudge(direction) }

    expect(draft_temp.reload.value).to eq(40.0)
  end
end
