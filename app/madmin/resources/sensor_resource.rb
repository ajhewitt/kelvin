class SensorResource < Madmin::Resource
  menu parent: "Refrigeration", position: 3

  # Attributes
  attribute :type, :select, collection: Sensor::TYPES, index: true, edit: false
  attribute :name
  attribute :slug, index: true
  attribute :is_virtual, index: true

  member_action do |sensor|
    link_to "Readings", madmin_sensor_readings_path(filters: [{column: "sensor_id", operator: "eq", value: sensor.id}]), class: "btn btn-secondary"
  end

  def self.display_name(sensor) = sensor.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
