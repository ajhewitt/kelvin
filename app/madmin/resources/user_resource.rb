class UserResource < Madmin::Resource
  menu position: 5

  # Attributes
  attribute :id, form: false, index: false, show: false
  attribute :username
  attribute :password, index: false, show: false, description: "At least 8 characters. Leave blank to keep the current one."
  attribute :password_confirmation, index: false, show: false
  attribute :created_at, form: false, index: true
  attribute :updated_at, form: false, index: false, show: false

  def self.display_name(user) = user.username

  def self.default_sort_column = "username"

  def self.default_sort_direction = "asc"
end
