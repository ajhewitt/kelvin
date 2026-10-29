class Configuration < ApplicationRecord
  # The slug of the configuration for serving, whose sessions can be for an event
  SERVING = "service"

  has_many :sessions, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true

  def self.serving = find_by(slug: SERVING)

  def serving? = slug == SERVING
end
