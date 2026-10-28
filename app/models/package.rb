class Package < ApplicationRecord
  TYPES = %w[Keg Cask Bottle Can].freeze
  # Kegs and casks are cooperage: served on draft and listed on the left of the board
  COOPERAGE_TYPES = %w[Keg Cask].freeze

  # Volumes under one unit are shown in the smaller measure: 128 US fl oz to the gallon,
  # 160 imperial fl oz to the imperial gallon, 1000 ml to the liter
  SMALL_UNITS = {"gal" => [128, "oz"], "imp_gal" => [160, "imp oz"], "liter" => [1000, "ml"]}.freeze
  UNIT_LABELS = {"gal" => "gal", "imp_gal" => "imp gal", "liter" => "L"}.freeze

  # The measures a size can be typed in, as printed on the package, each with its unit and how
  # many make one: the smaller measures first, as in a 12 oz can, then the units themselves
  MEASURES = SMALL_UNITS.to_h { |unit, (factor, label)| [label, [unit, factor]] }
    .merge(UNIT_LABELS.to_h { |unit, label| [label, [unit, 1]] }).freeze

  enum :unit, {gal: "gal", imp_gal: "imp_gal", liter: "liter"}, validate: true

  has_many :drink_packages, dependent: :restrict_with_error

  # A new type could move drinks already listed in the package to the other side of the board
  attr_readonly :type

  attr_writer :amount, :measure

  scope :cooperage, -> { where(type: COOPERAGE_TYPES) }
  scope :packaged, -> { where.not(type: COOPERAGE_TYPES) }

  before_validation :volume_from_size, if: -> { @amount || @measure }

  validates :type, inclusion: {in: TYPES}
  validates :volume, numericality: {greater_than: 0}
  validates :volume, uniqueness: {scope: [:type, :unit]}
  validates :amount, numericality: {greater_than: 0}, if: -> { @amount }
  validates :measure, inclusion: {in: MEASURES.keys}, if: -> { @measure }

  def cooperage?
    type.in?(COOPERAGE_TYPES)
  end

  # The size as typed in the admin, "12" "oz" for a 0.09375 gal can, until it's changed
  def amount
    @amount || volume_parts&.first
  end

  def measure
    @measure || volume_parts&.last
  end

  # "5 gal", "4.5 imp gal" or "20 L", and under one unit "16 oz", "20 imp oz" or "660 ml"
  def volume_label
    volume_parts&.join(" ")
  end

  # Only bottles show their size on the board
  def board_size
  end

  def to_s
    "#{type} #{volume_label}"
  end

  private

  def volume_from_size
    unit, factor = MEASURES[measure]
    number = Float(amount, exception: false)
    return unless unit && number

    self.unit = unit
    self.volume = number / factor
  end

  def volume_parts
    return unless volume && UNIT_LABELS.key?(unit)

    amount, label =
      if volume < 1
        factor, small_unit = SMALL_UNITS.fetch(unit)
        [volume * factor, small_unit]
      else
        [volume, UNIT_LABELS.fetch(unit)]
      end
    [ActiveSupport::NumberHelper.number_to_rounded(amount, precision: 2, strip_insignificant_zeros: true), label]
  end
end
