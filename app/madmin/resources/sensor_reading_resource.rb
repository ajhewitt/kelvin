# A log the hardware writes, so it's for looking through: newest first, filtered by time, value,
# sensor or session
class SensorReadingResource < Madmin::Resource
  menu parent: "Logs", position: 1

  # Attributes
  attribute :recorded_at, index: true
  attribute :sensor, index: true
  attribute :reading_value, index: true
  attribute :session, index: true

  # Only for filtering, as the sensor and session pages do
  attribute :sensor_id, index: false, show: false
  attribute :session_id, index: false, show: false

  def self.readonly? = true

  def self.display_name(reading) = "#{reading.sensor.name}, #{I18n.l(reading.recorded_at, format: :short)}"

  # Newest first by id, the order the hardware wrote them in, which takes no sorting or extra
  # index however long the log grows
  def self.default_sort_column = "id"
end
