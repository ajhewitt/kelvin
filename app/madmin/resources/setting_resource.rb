# A session's settings, reached from the session's page rather than the sidebar
class SettingResource < Madmin::Resource
  menu false

  # Attributes
  attribute :session, index: true
  attribute :key, index: true
  attribute :value, index: true

  def self.display_name(setting) = "#{setting.key}: #{setting.value}"
end
