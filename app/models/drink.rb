class Drink < ApplicationRecord
  # Drinks without a brand are the house's own
  belongs_to :brand, optional: true
  has_many :drink_packages, dependent: :destroy

  validates :name, presence: true
  validates :abv, numericality: {in: 0..100}, allow_nil: true
  validates :ibu, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true
  validates :srm, numericality: {greater_than_or_equal_to: 0}, allow_nil: true
end
