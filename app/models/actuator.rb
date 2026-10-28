class Actuator < ApplicationRecord
  # The kinds of actuator, each a subclass in its own file
  TYPES = %w[UartActuator PwmActuator LogicLevelActuator].freeze

  has_many :control_actions, dependent: :destroy
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :type, inclusion: {in: TYPES}

  # Stub method that subclasses overwrite with raw physical protocols
  def trigger!(value)
    raise NotImplementedError, "Subclasses must implement physical execution logic"
  end
end
