class BrandResource < Madmin::Resource
  menu parent: "Tap list", position: 3

  # Attributes
  attribute :name
  attribute :country, index: true

  # Associations
  attribute :drinks, form: false

  member_action do |brand|
    if brand.drinks.any?
      tag.span "Deleting it also deletes its #{pluralize(brand.drinks.size, "drink")}", class: "form-description"
    end
  end

  def self.display_name(brand) = brand.name

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
