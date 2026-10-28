# An event's tap list as shown on the TV: cooperage on the left, bottles and cans on the right.
# Each side lists the house's own drinks first under the side's heading, when there are any,
# then a section per brand in the order the brands first appear on the list.
class Board
  Side = Data.define(:sections, :stats)
  # The house's own section has no brand
  Section = Data.define(:title, :brand, :items)

  SIDE_TITLES = {cooperage: "Tap List", packaged: "Bottle List"}.freeze

  attr_reader :event

  def initialize(event)
    @event = event
  end

  def tagline
    event&.tagline
  end

  def theme
    event&.theme || "classic"
  end

  def left
    side(:cooperage)
  end

  def right
    side(:packaged)
  end

  private

  def items
    @items ||= event ? event.drink_packages.includes(:package, drink: [:brand, {image_attachment: :blob}]).order(:position).to_a : []
  end

  def side(kind)
    on_side = items.select { |item| item.cooperage? == (kind == :cooperage) }
    # A stat only gets a column on a side when some drink there has a value for it
    stats = (event&.stats || []).select { |stat| on_side.any? { |item| item.drink.public_send(stat) } }
    Side.new(sections: sections(kind, on_side), stats: stats)
  end

  def sections(kind, on_side)
    by_brand = on_side.group_by { |item| item.drink.brand }
    house = by_brand.delete(nil)
    branded = by_brand.map { |brand, brand_items| Section.new(title: brand.name, brand: brand, items: brand_items) }
    house ? [Section.new(title: SIDE_TITLES.fetch(kind), brand: nil, items: house), *branded] : branded
  end
end
