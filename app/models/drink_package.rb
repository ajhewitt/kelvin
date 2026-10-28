# A drink in a package on an event's list, numbered within its side of the board:
# cooperage (kegs and casks) on the left, bottles and cans on the right
class DrinkPackage < ApplicationRecord
  belongs_to :event
  belongs_to :drink
  belongs_to :package

  delegate :cooperage?, to: :package

  validates :drink_id, uniqueness: {scope: [:event_id, :package_id], message: "is already listed in that package"}
  validates :position, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
  validates :emoji, length: {maximum: 16}
  validate :position_unique_on_its_side, if: -> { position && event && package }

  before_create :insert_in_section, unless: :position
  after_destroy :close_gap

  # The other items on this item's side of the board
  def siblings
    event.drink_packages.joins(:package).merge(cooperage? ? Package.cooperage : Package.packaged).where.not(id: id)
  end

  # The other items in this item's section of the board: the same brand's drinks, or the house's
  # own, on the same side
  def section_siblings
    siblings.joins(:drink).where(drinks: {brand_id: drink.brand_id})
  end

  # The drink's image, unless it's switched off for this event
  def image
    drink.image if show_image? && drink.image.attached?
  end

  # Swaps places with the next item up or down its section
  def move(direction)
    neighbor =
      if direction == :up
        section_siblings.where(position: ...position).order(position: :desc).first
      else
        section_siblings.where(position: (position + 1)..).order(:position).first
      end
    return unless neighbor

    transaction do
      neighbor_position = neighbor.position
      neighbor.update_column(:position, position)
      update_column(:position, neighbor_position)
    end
  end

  # Moves this item's brand, with all its drinks, up or down past the next brand on its side,
  # renumbering the side in board order. The house's own drinks stay first.
  def move_brand(direction)
    sections = [self, *siblings.includes(:drink)].sort_by(&:position).group_by { |item| item.drink.brand_id }
    house = sections.delete(nil) || []
    brands = sections.keys
    from = brands.index(drink.brand_id)
    to = from && ((direction == :up) ? from - 1 : from + 1)
    return unless to&.between?(0, brands.size - 1)

    brands[from], brands[to] = brands[to], brands[from]
    transaction do
      [*house, *sections.values_at(*brands).flatten].each.with_index(1) { |item, index| item.update_column(:position, index) }
    end
  end

  private

  # New items go in ABV order within their section, before the first stronger drink of the same
  # brand on their side, with drinks that have no ABV counting as strongest. A brand that's new
  # to the side starts a section at the bottom.
  def insert_in_section
    stronger = drink.abv && section_siblings.where("drinks.abv > ? OR drinks.abv IS NULL", drink.abv).order(:position).first
    self.position = stronger&.position || (section_siblings.maximum(:position) || siblings.maximum(:position)).to_i + 1
    shift(siblings.where(position: position..), 1)
  end

  def close_gap
    shift(siblings.where(position: (position + 1)..), -1)
  end

  # Updates by id because SQLite can't tell which table "position" means in an update with a join
  def shift(items, by)
    DrinkPackage.where(id: items.select(:id)).update_all(["position = position + ?", by])
  end

  def position_unique_on_its_side
    errors.add(:position, "is already taken on that side of the board") if siblings.exists?(position: position)
  end
end
