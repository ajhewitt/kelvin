class ActuatorResource < Madmin::Resource
  menu parent: "Refrigeration", position: 4

  # Attributes
  attribute :type, :select, collection: Actuator::TYPES, index: true, edit: false
  attribute :name
  attribute :slug, index: true

  member_action do |actuator|
    link_to "Control actions", madmin_control_actions_path(filters: [{column: "actuator_id", operator: "eq", value: actuator.id}]), class: "btn btn-secondary"
  end

  def self.display_name(actuator) = actuator.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
