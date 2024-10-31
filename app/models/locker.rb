class Locker < ApplicationRecord
  belongs_to :controller
  has_many :locker_passwords
  has_many :gestures, through: :locker_passwords
  has_many :locker_events

  validates :number, presence: true
  validates :owner_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
end

