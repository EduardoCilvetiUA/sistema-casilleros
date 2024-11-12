class LockerEvent < ApplicationRecord
  belongs_to :locker

  validates :event_type, presence: true
  validates :event_time, presence: true

  scope :successful, -> { where(success: true) }
  scope :failed, -> { where(success: false) }
  scope :recent, -> { where("event_time > ?", 24.hours.ago) }
end
