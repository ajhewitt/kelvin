class Session < ApplicationRecord
  belongs_to :configuration
  has_many :control_actions, dependent: :destroy
  has_many :sensor_readings, dependent: :destroy

  enum :status, { pending: 0, active: 1, inactive: 2, complete: 3 }, default: :pending

  validate :ensure_lifecycle_integrity, on: :update

  def elapsed_minutes
    return 0 unless started_at
    (( (ended_at || Time.current) - started_at) / 60).to_i
  end

  private

  def ensure_lifecycle_integrity
    return unless status_changed?
    if status_was.to_sym == :complete
      errors.add(:status, "cannot be altered after session completion")
    end
    if status_was.to_sym == :inactive && status.to_sym == :pending
      errors.add(:status, "cannot transition backward from paused to pending")
    end
  end
end
