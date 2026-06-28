class Actuator < ApplicationRecord
  has_many :control_actions, dependent: :destroy
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  
  # Stub method that subclasses overwrite with raw physical protocols
  def trigger!(value)
    raise NotImplementedError, "Subclasses must implement physical execution logic"
  end
end

class UartActuator < Actuator
  def trigger!(value)
    # Put Modbus RTU serial packet transmission code here
  end
end

class PwmActuator < Actuator
  def trigger!(value)
    # Put duty cycle sysfs/hardware pin modifications here
  end
end

class LogicLevelActuator < Actuator
  def trigger!(value)
    # Put digital high/low pin switching code here
  end
end
