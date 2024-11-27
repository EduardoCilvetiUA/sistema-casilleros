class Model < ApplicationRecord
  has_many :gestures, dependent: :restrict_with_error
  has_many :controllers, dependent: :restrict_with_error
  has_many :model_updates, dependent: :destroy

  accepts_nested_attributes_for :gestures,
  allow_destroy: true,
  reject_if: :all_blank

  validates :name, presence: true
  before_destroy :check_gesture_usage

  private

  def check_gesture_usage
    if gestures.joins(:locker_passwords).any?
      errors.add(:base, "No se puede eliminar un modelo que está asignado a un casillero")
      throw :abort
    end
  end
end
