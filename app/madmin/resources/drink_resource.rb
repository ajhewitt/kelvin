class DrinkResource < Madmin::Resource
  menu position: 2

  # Attributes
  attribute :name
  attribute :brand, field: BrandField, index: true
  attribute :abv, index: true
  attribute :ibu, index: true
  attribute :srm, index: true
  attribute :description, index: false
  attribute :image, index: false

  member_action do |drink|
    if (event = Event.current)
      link_to "Add to #{event.name}", madmin_event_drink_packages_path(event, drink_id: drink.id, anchor: "add"), class: "btn btn-primary"
    end
  end

  # A drink that comes back with different numbers gets a copy to change, so earlier
  # events keep the numbers they had
  member_action do |drink|
    button_to "Copy as new brew", copy_madmin_drink_path(drink), class: "btn btn-secondary"
  end

  def self.display_name(drink) = drink.to_s

  def self.default_sort_column = "name"

  def self.default_sort_direction = "asc"
end
