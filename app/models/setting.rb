# A value a session holds to, like a serving session's draft temperature. The sensor whose slug is
# the setting's key reads what it sets.
class Setting < ApplicationRecord
  # How far the list's up and down buttons move a setting
  STEP = 1.0

  belongs_to :session

  validates :key, presence: true, uniqueness: {scope: :session_id}
  validates :value, numericality: true

  # The latest reading in the setting's session from the sensor named by its key
  def reading
    sensor = Sensor.find_by(slug: key)
    sensor && session.sensor_readings.where(sensor: sensor).order(:id).last
  end

  # A step up or down, from the list's buttons
  def nudge(direction) = update(value: value + ((direction == :up) ? STEP : -STEP))
end
