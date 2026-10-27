class Event < ApplicationRecord
  has_many :drink_packages, dependent: :destroy

  before_destroy :keep_last_event, prepend: true

  validates :name, presence: true
  validates :date, presence: true, uniqueness: true

  # Event days run noon to noon UTC (8am to 8am EDT, 7am to 7am EST), so an event that
  # goes past midnight stays on its own date until the next morning
  def self.business_date(time = Time.current)
    (time.utc - 12.hours).to_date
  end

  # Today's event or the next one coming up, otherwise the most recent past event
  def self.current(time = Time.current)
    where(date: business_date(time)..).order(:date).first || order(date: :desc).first
  end

  # The drink stats the board shows for this event, in board order
  def stats
    {srm: show_srm?, ibu: show_ibu?, abv: show_abv?}.select { |_stat, shown| shown }.keys
  end

  private

  # The board always shows an event
  def keep_last_event
    return if Event.where.not(id: id).exists?

    errors.add(:base, "The last event can't be deleted")
    throw :abort
  end
end
