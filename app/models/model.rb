class Model < ApplicationRecord
  has_many :gestures, dependent: :destroy
  has_many :controllers
  has_many :model_updates, dependent: :destroy

  validates :name, presence: true
  validates :file_path, presence: true, if: :active?
  validates :size_bytes, presence: true, numericality: { greater_than: 0 }, if: :active?
end
