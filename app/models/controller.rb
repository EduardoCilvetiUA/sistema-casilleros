class Controller < ApplicationRecord
  belongs_to :user
  belongs_to :model
  has_many :lockers
  has_many :model_updates

  validates :name, presence: true
  validates :location, presence: true
  validate :lockers_limit_not_exceeded

  def update_connection_status(status)
    update(
      is_connected: status,
      last_connection: status ? Time.current : last_connection
    )
  end

  private

  def lockers_limit_not_exceeded
    if lockers.count >= 4
      errors.add(:base, "El controlador ya tiene el número máximo de casilleros (4).")
    end
  end
end
