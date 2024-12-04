class Controller < ApplicationRecord
  belongs_to :user
  belongs_to :model, optional: true
  has_many :lockers, dependent: :destroy
  has_many :model_updates, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :location, presence: true
  validates :model, presence: { message: "Debes tener un modelo activo" }
  validate :lockers_limit_not_exceeded

  def update_connection_status(status)
    update(
      is_connected: status,
      last_connection: status ? Time.current : last_connection
    )
  end

  def self.human_attribute_name(attr, options = {})
    attr == 'model' ? '' : super
  end

  private

  def lockers_limit_not_exceeded
    if lockers.count >= 4
      errors.add(:base, "El controlador ya tiene el número máximo de casilleros (4).")
    end
  end
end
