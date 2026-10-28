class Sensor < ApplicationRecord
  # The kinds of sensor, each a subclass in its own file
  TYPES = %w[OneWireSensor FlowPulseSensor ModbusReadSensor VirtualSensor].freeze

  has_many :sensor_readings, dependent: :destroy
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :type, inclusion: {in: TYPES}

  # Stub method that subclasses overwrite to read their respective endpoints
  def read_value
    raise NotImplementedError, "Subclasses must implement data-gathering logic"
  end
end
