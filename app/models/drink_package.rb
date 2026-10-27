# A drink in a package on an event's list, numbered within its side of the board:
# cooperage (kegs and casks) on the left, bottles and cans on the right
class DrinkPackage < ApplicationRecord
  belongs_to :event
  belongs_to :drink
  belongs_to :package

  delegate :cooperage?, to: :package

  validates :drink_id, uniqueness: {scope: [:event_id, :package_id], message: "is already listed in that package"}
  validates :position, numericality: {only_integer: true, greater_than: 0}, allow_nil: true
  validate :position_unique_on_its_side, if: -> { position && event && package }

  before_create :insert_by_abv, unless: :position
  after_destroy :close_gap

  # The other items on this item's side of the board
  def siblings
    event.drink_packages.joins(:package).merge(cooperage? ? Package.cooperage : Package.packaged).where.not(id: id)
  end

  # Moves this item to a position on its side, renumbering the side from 1
  def move_to(new_position)
    transaction do
      ordered = siblings.order(:position).to_a
      ordered.insert((new_position - 1).clamp(0, ordered.size), self)
      ordered.each.with_index(1) { |item, index| item.update_column(:position, index) }
    end
  end

  private

  # New items go before the first stronger drink on their side, with drinks that have no ABV
  # counting as strongest, so a side stays in ABV order unless it has been rearranged
  def insert_by_abv
    stronger = drink.abv && siblings.joins(:drink).where("drinks.abv > ? OR drinks.abv IS NULL", drink.abv).order(:position).first
    if stronger
      self.position = stronger.position
      shift(siblings.where(position: position..), 1)
    else
      self.position = siblings.maximum(:position).to_i + 1
    end
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
