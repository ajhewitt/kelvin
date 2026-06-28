class Configuration < ApplicationRecord
  has_many :sessions, dependent: :destroy
  
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
