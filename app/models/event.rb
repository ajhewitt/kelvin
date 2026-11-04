class Event < ApplicationRecord
  # The board's looks, in the groups the admin shows them in. Each but Classic restyles the board with
  # app/assets/stylesheets/themes/<name>.css
  THEME_GROUPS = {
    "Pub classics" => {
      "classic" => "Coral on deep purple, the original board",
      "public_house" => "Gold leaf on oxblood, like a pub sign",
      "racing_green" => "Cream and brass on British racing green",
      "admiralty" => "Brass on navy in a double frame",
      "tudor" => "Cream and oxblood on black, like timber framing",
      "gin_palace" => "Silver and sage on Victorian teal",
      "tweed" => "Mustard and oatmeal on country tweed",
      "frost" => "Ice and silver on winter slate, in light, wide capitals",
      "chalkboard" => "Chalk on slate in a wooden frame",
      "broadsheet" => "A newspaper front page, its blackletter nameplate and Caslon in black and red on newsprint",
      "cotswold" => "Slate and moss on honey stone",
      "wedgwood" => "White on jasperware blue"
    },
    "Around the world" => {
      "grand_place" => "Gold leaf on limestone in royal capitals, like the Grand-Place in Brussels",
      "trappist" => "Gothic letters in weathered limestone under a great stone arch, like a Trappist abbey",
      "beer_hall" => "White Fraktur on Bavarian blue under the diamonds, like an Oktoberfest hall",
      "absinthe" => "Cream Art Nouveau on absinthe green in a whiplash frame, like a Belle Époque poster",
      "art_deco" => "Gold on black in a frame of fans and stepped corners, like a twenties speakeasy",
      "dublin" => "Gilded uncials on a green fascia between gold shamrocks, like an Irish pub front"
    },
    "Breweries" => {
      "pretty_things" => "Red hand-cut capitals on a label in a turquoise flower trim, like Pretty Things Beer & Ale Project's",
      "smod" => "A light blue sky over a grey brick works and smokestacks, its windows holding the drinks, like Saint Mars of the Desert's mural"
    },
    "Bold and retro" => {
      "neon" => "Neon signs behind the bar",
      "cyberpunk" => "Tech-noir neon in a red heads-up display, from a dystopian future",
      "synthwave" => "Chrome and a striped sunset over neon, straight out of 1985",
      "arcade" => "Pixel type in a blue maze, like a 1982 high-score table",
      "disco" => "Gold and tangerine stripes under a seventies sunburst",
      "matrix" => "Green code raining down a black terminal, like The Matrix",
      "industrial" => "Diamond plate and brushed steel, like an early-nineties brewpub"
    }
  }.freeze

  THEMES = THEME_GROUPS.values.reduce(:merge).freeze

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
