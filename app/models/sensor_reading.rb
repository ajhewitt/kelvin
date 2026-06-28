class SensorReading < ApplicationRecord
  belongs_to :session
  belongs_to :sensor
  validates :reading_value, :recorded_at, presence: true
end
