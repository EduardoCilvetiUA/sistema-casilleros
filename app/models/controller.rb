class Controller < ApplicationRecord
  belongs_to :user
  belongs_to :model
  has_many :lockers
  has_many :model_updates

  validates :name, presence: true
  validates :location, presence: true
  def update_connection_status(status)
    update(
      is_connected: status,
      last_connection: status ? Time.current : last_connection
    )
  end
end
