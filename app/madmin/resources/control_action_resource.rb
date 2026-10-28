# A log the hardware writes, so it's for looking through: newest first, filtered by time, value,
# actuator or session
class ControlActionResource < Madmin::Resource
  menu parent: "Logs", position: 2

  # Attributes
  attribute :executed_at, index: true
  attribute :actuator, index: true
  attribute :action_value, index: true
  attribute :session, index: true

  # Only for filtering, as the actuator and session pages do
  attribute :actuator_id, index: false, show: false
  attribute :session_id, index: false, show: false

  def self.readonly? = true

  def self.display_name(action) = "#{action.actuator.name}, #{I18n.l(action.executed_at, format: :short)}"

  # Newest first by id, the order the hardware wrote them in, which takes no sorting or extra
  # index however long the log grows
  def self.default_sort_column = "id"
end
