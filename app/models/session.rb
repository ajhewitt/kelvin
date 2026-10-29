class Session < ApplicationRecord
  # A serving session's one setting: the temperature to serve at, in °F, which the sensor with the
  # slug draft_temp reads
  DRAFT_TEMP = "draft_temp"
  DRAFT_TEMP_DEFAULT = 38.0

  belongs_to :configuration
  # A serving session can be for an event, one session to an event
  belongs_to :event, optional: true
  has_many :control_actions, dependent: :destroy
  has_many :sensor_readings, dependent: :destroy
  has_many :settings, dependent: :destroy

  enum :status, {pending: 0, active: 1, inactive: 2, complete: 3}, default: :pending

  validates :event_id, uniqueness: {message: "already has a serving session"}, allow_nil: true
  validate :event_only_when_serving
  validate :ensure_lifecycle_integrity, on: :update

  # The start time as a session leaves pending, whatever for, and the end time as it completes,
  # unless they're set already
  before_save :stamp_times
  after_create :add_draft_temp, if: :serving?

  def serving? = configuration&.serving?

  def draft_temp = settings.find_by(key: DRAFT_TEMP)

  # The serving session's start and stop buttons on the event's list: start runs a pending or
  # stopped session, and stop stops a running session or completes a stopped one, which can't be
  # started again
  def can_start? = pending? || inactive?

  def can_stop? = active? || inactive?

  def start = can_start? && update(status: :active)

  def stop = can_stop? && update(status: active? ? :inactive : :complete)

  def elapsed_minutes
    return 0 unless started_at
    (((ended_at || Time.current) - started_at) / 60).to_i
  end

  private

  def add_draft_temp = settings.create!(key: DRAFT_TEMP, value: DRAFT_TEMP_DEFAULT)

  def stamp_times
    self.started_at ||= Time.current unless pending?
    self.ended_at ||= Time.current if complete?
  end

  def event_only_when_serving
    errors.add(:event, "is only for serving sessions") if event && !serving?
  end

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
