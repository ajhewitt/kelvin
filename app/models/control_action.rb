class ControlAction < ApplicationRecord
  belongs_to :session
  belongs_to :actuator
  validates :action_value, :executed_at, presence: true
end
