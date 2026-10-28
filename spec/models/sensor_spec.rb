require "rails_helper"

RSpec.describe Sensor, type: :model do
  it "instantiates the subclass named by each of its types" do
    expect(Sensor::TYPES.map { |type| Sensor.new(type: type).class.name }).to eq(Sensor::TYPES)
  end

  it "requires one of the sensor types" do
    sensor = Sensor.new(name: "Keg Fridge Temp", slug: "keg_temp")

    expect(sensor).not_to be_valid
    expect(sensor.errors.attribute_names).to eq([:type])
  end
end
