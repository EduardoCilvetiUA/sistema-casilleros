class LockerPassword < ApplicationRecord
  belongs_to :locker
  belongs_to :gesture

  validates :position, presence: true,
                      numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 4 }
end
