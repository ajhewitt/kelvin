class Drink < ApplicationRecord
  # Drinks without a brand are the house's own
  belongs_to :brand, optional: true
  has_many :drink_packages, dependent: :destroy
  has_one_attached :image do |attachable|
    attachable.variant :thumb, resize_to_limit: [240, 240]
  end

  validates :name, presence: true
  validates :abv, numericality: {in: 0..100}, allow_nil: true
  validates :ibu, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validates :srm, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
  validate :image_is_a_picture, if: -> { image.attached? }

  private

  def image_is_a_picture
    return if image.content_type.in?(%w[image/png image/jpeg image/gif image/webp])

    errors.add(:image, "must be a PNG, JPEG, GIF or WebP")
  end
end
