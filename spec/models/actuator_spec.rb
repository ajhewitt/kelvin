require "rails_helper"

RSpec.describe Actuator, type: :model do
  it "instantiates the subclass named by each of its types" do
    expect(Actuator::TYPES.map { |type| Actuator.new(type: type).class.name }).to eq(Actuator::TYPES)
  end

  it "requires one of the actuator types" do
    actuator = Actuator.new(name: "Coolant Pump Duty", slug: "pump_speed")

    expect(actuator).not_to be_valid
    expect(actuator.errors.attribute_names).to eq([:type])
  end
end
