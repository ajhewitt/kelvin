class Event < ApplicationRecord
  # The board's looks, each but Classic restyling the board with app/assets/stylesheets/themes/<name>.css
  THEMES = {
    "classic" => "Coral on deep purple, the original board",
    "public_house" => "Gold leaf on oxblood, like a pub sign",
    "racing_green" => "Cream and brass on British racing green",
    "stout" => "Cream and gold on black, like a pint of stout",
    "admiralty" => "Brass on navy in a double frame",
    "mahogany" => "Amber and copper on dark wood",
    "tudor" => "Cream and oxblood on black, like timber framing",
    "gin_palace" => "Silver and sage on Victorian teal",
    "tweed" => "Mustard and oatmeal on country tweed",
    "pewter" => "Quiet greys, like a pewter tankard",
    "frost" => "Ice and silver on winter slate",
    "hop_garden" => "Hop green on deep forest, with gold rules",
    "chalkboard" => "Chalk on slate in a wooden frame",
    "neon" => "Neon signs behind the bar",
    "letterpress" => "Red and black type on warm paper",
    "broadsheet" => "Black on newsprint, like a newspaper masthead",
    "cotswold" => "Slate and moss on honey stone",
    "wedgwood" => "White on jasperware blue"
  }.freeze

  has_many :drink_packages, dependent: :destroy

  before_destroy :keep_last_event, prepend: true

  validates :name, presence: true
  validates :date, presence: true, uniqueness: true
  validates :theme, inclusion: {in: THEMES.keys}

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
