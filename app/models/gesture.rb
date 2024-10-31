class Gesture < ApplicationRecord
  belongs_to :model
  has_many :locker_passwords
  has_many :lockers, through: :locker_passwords

  validates :name, presence: true
  validates :symbol, presence: true
end
