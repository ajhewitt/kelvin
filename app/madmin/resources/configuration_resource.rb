class ConfigurationResource < Madmin::Resource
  menu parent: "Refrigeration", position: 1

  # Attributes
  attribute :name
  attribute :slug, index: true
  attribute :description, index: true

  # Associations
  attribute :sessions, form: false

  def self.display_name(configuration) = configuration.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
