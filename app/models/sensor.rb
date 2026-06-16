class Sensor < ApplicationRecord
  has_many :sensor_readings, dependent: :destroy
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  # Stub method that subclasses overwrite to read their respective endpoints
  def read_value
    raise NotImplementedError, "Subclasses must implement data-gathering logic"
  end
end

class OneWireSensor < Sensor
  def read_value
    # Put w1_slave file parsing logic here
  end
end

class FlowPulseSensor < Sensor
  def read_value
    # Put frequency calculation logic here
  end
end

class ModbusReadSensor < Sensor
  def read_value
    # Put UART register polling code here
  end
end

class VirtualSensor < Sensor
  def read_value
    # Put mathematical/thermodynamic software calculation functions here
  end
end
