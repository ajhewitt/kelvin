class Brand < ApplicationRecord
  has_many :drinks, dependent: :destroy

  validates :name, presence: true, uniqueness: true
end
