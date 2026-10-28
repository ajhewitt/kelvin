class EventResource < Madmin::Resource
  menu parent: "Tap list", position: 1

  # Attributes
  attribute :date, index: true
  attribute :name
  attribute :tagline, index: true
  attribute :description, index: false
  attribute :show_abv, index: false
  attribute :show_ibu, index: false
  attribute :show_srm, index: false, description: "The board shows them in the order SRM, IBU, ABV, skipping drinks without a value"
  attribute :theme, field: ThemeField, index: true

  # The drinks on the list have their own page
  member_action collection: true do |event|
    link_to "List", madmin_event_drink_packages_path(event), class: "btn btn-primary"
  end

  member_action do |event|
    link_to "Themes", themes_madmin_event_path(event), class: "btn btn-secondary"
  end

  member_action do |event|
    link_to "Board", event_board_path(event), class: "btn btn-secondary", target: "_blank"
  end

  def self.display_name(event) = event.name

  def self.default_sort_column = "date"
end
