class PackageResource < Madmin::Resource
  menu position: 4

  # Attributes
  attribute :type, :select, collection: Package::TYPES, index: true, edit: false
  attribute :size, field: SizeField, index: true

  def self.display_name(package) = package.to_s

  def self.default_sort_column = "type"

  def self.default_sort_direction = "asc"
end
