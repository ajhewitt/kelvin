# A login for the admin screens
class User < ApplicationRecord
  has_secure_password

  # A login lasts until its password changes
  generates_token_for :login do
    password_salt.last(10)
  end

  normalizes :username, with: ->(username) { username.strip.downcase }

  before_destroy :keep_last_user, prepend: true

  validates :username, presence: true, uniqueness: true
  validates :password, length: {minimum: 8}, allow_nil: true

  private

  # Someone always needs to be able to log in
  def keep_last_user
    return if User.where.not(id: id).exists?

    errors.add(:base, "The last user can't be deleted")
    throw :abort
  end
end
