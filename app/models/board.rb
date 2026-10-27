# An event's tap list as shown on the TV: cooperage on the left, bottles and cans on the right.
# Each side lists the house's own drinks first under the side's heading, when there are any,
# then a section per brand in the order the brands first appear on the list.
class Board
  Section = Data.define(:title, :items)

  SIDE_TITLES = {cooperage: "Tap List", packaged: "Bottle List"}.freeze

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def tagline
    event&.tagline
  end

  def left
    sections(:cooperage)
  end

  def right
    sections(:packaged)
  end

  private

  def items
    @items ||= event ? event.drink_packages.includes(:package, drink: [:brand, {image_attachment: :blob}]).order(:position).to_a : []
  end

  def sections(side)
    by_brand = items.select { |item| item.cooperage? == (side == :cooperage) }.group_by { |item| item.drink.brand }
    house = by_brand.delete(nil)
    branded = by_brand.map { |brand, brand_items| Section.new(title: brand.name, items: brand_items) }
    house ? [Section.new(title: SIDE_TITLES.fetch(side), items: house), *branded] : branded
  end
end
