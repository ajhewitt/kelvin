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
    "grand_place" => "Gold leaf and verdigris on Brussels stone, under striped awnings",
    "chalkboard" => "Chalk on slate in a wooden frame",
    "letterpress" => "Red and black type on warm paper",
    "broadsheet" => "Black on newsprint, like a newspaper masthead",
    "cotswold" => "Slate and moss on honey stone",
    "wedgwood" => "White on jasperware blue",
    # Bolder looks, from neon signs to a brewpub
    "neon" => "Neon signs behind the bar",
    "cyberpunk" => "Tech-noir neon in a red heads-up display, from a dystopian future",
    "synthwave" => "Chrome and a striped sunset over neon, straight out of 1985",
    "arcade" => "Pixel type in a blue maze, like a 1982 high-score table",
    "disco" => "Gold and tangerine stripes under a seventies sunburst",
    "matrix" => "Green code raining down a black terminal, like The Matrix",
    "industrial" => "Diamond plate and brushed steel, like an early-nineties brewpub"
  }.freeze

  # Hidden themes, left out of the admin's lists until found: the Themes page shows them after the
  # Konami code on a keyboard, or five quick taps on its title. An event using one shows it as usual
  EASTER_EGGS = {
    "trump" => "Gold on gold on black marble, as gilded as Trump Tower"
  }.freeze

  ALL_THEMES = THEMES.merge(EASTER_EGGS).freeze

  has_many :drink_packages, dependent: :destroy
  # Started and stopped from the event's page; its logs stay if the event is deleted
  has_one :serving_session, class_name: "Session", dependent: :nullify

  before_destroy :keep_last_event, prepend: true

  validates :name, presence: true
  validates :date, presence: true, uniqueness: true
  validates :theme, inclusion: {in: ALL_THEMES.keys}

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
