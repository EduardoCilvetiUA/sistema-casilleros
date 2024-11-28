class Model < ApplicationRecord
  has_one_attached :file

  has_many :gestures, dependent: :restrict_with_error
  has_many :controllers, dependent: :restrict_with_error
  has_many :model_updates, dependent: :destroy

  accepts_nested_attributes_for :gestures,
                                allow_destroy: true,
                                reject_if: :all_blank

  validates :name, presence: true
  validates :file, presence: true
  validate :file_size_validation, if: -> { file.attached? }

  before_destroy :check_gesture_usage
  after_save :update_file_size, if: -> { file.attached? }

  private

  def file_size_validation
    if file.blob.present? && file.blob.byte_size > 15.megabytes
      errors.add(:file, "El archivo no debe superar los 15 MB")
    end
  end

  def update_file_size
    self.update_column(:size_bytes, file.blob.byte_size)
  end

  def check_gesture_usage
    if gestures.joins(:locker_passwords).any?
      errors.add(:base, "No se puede eliminar un modelo que está asignado a un casillero")
      throw :abort
    end
  end
end
