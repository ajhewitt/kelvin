class Session < ApplicationRecord
  belongs_to :configuration
  # A serving session can be for an event, one session to an event
  belongs_to :event, optional: true
  has_many :control_actions, dependent: :destroy
  has_many :sensor_readings, dependent: :destroy

  enum :status, {pending: 0, active: 1, inactive: 2, complete: 3}, default: :pending

  validates :event_id, uniqueness: {message: "already has a serving session"}, allow_nil: true
  validate :event_only_when_serving
  validate :created_pending, on: :create
  validate :ensure_lifecycle_integrity, on: :update

  # A session can't go back to pending or change once complete, so this stamps the start time as
  # it leaves pending, whatever for, and the end time as it completes
  before_save :stamp_times

  def serving? = configuration&.serving?

  # The start and stop buttons: start runs a pending or stopped session, and stop stops a running
  # session or completes a stopped one, which can't be started again
  def can_start? = pending? || inactive?

  def can_stop? = active? || inactive?

  def start = can_start? && update(status: :active)

  def stop = can_stop? && update(status: active? ? :inactive : :complete)

  def elapsed_minutes
    return 0 unless started_at
    (((ended_at || Time.current) - started_at) / 60).to_i
  end

  private

  def stamp_times
    self.started_at ||= Time.current unless pending?
    self.ended_at ||= Time.current if complete?
  end

  def created_pending
    errors.add(:status, "must be pending when a session is created") unless pending?
  end

  def event_only_when_serving
    errors.add(:event, "is only for serving sessions") if event && !serving?
  end

  def ensure_lifecycle_integrity
    return unless status_changed?
    if status_was.to_sym == :complete
      errors.add(:status, "cannot be altered after session completion")
    end
    if pending?
      errors.add(:status, "cannot transition backward to pending once started")
    end
  end
end
