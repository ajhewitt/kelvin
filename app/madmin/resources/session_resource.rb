class SessionResource < Madmin::Resource
  menu parent: "Refrigeration", position: 2

  # Attributes
  attribute :configuration, index: true
  attribute :event, index: true, description: "For a serving session, which the event's page can then start and stop"
  # Changed by the start and stop buttons, which stamp the start and end times
  attribute :status, field: SessionStatusField, index: true, form: false
  attribute :started_at, index: true, form: false
  attribute :ended_at, index: true, form: false
  attribute :created_at, form: false, index: false

  # A session's readings and actions run to thousands, so they're in the logs, filtered
  member_action do |session|
    link_to "Sensor readings", madmin_sensor_readings_path(filters: [{column: "session_id", operator: "eq", value: session.id}]), class: "btn btn-secondary"
  end

  member_action do |session|
    link_to "Control actions", madmin_control_actions_path(filters: [{column: "session_id", operator: "eq", value: session.id}]), class: "btn btn-secondary"
  end

  def self.display_name(session) = "#{session.configuration.name} ##{session.id}"
end
