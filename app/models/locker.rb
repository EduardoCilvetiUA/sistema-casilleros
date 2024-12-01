class Locker < ApplicationRecord
  belongs_to :controller
  has_many :locker_passwords
  has_many :gestures, through: :locker_passwords
  has_many :locker_events

  validates :number, presence: true, uniqueness: { scope: :controller_id }
  validates :owner_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Método para obtener la contraseña del casillero
  def password_sequence
    locker_passwords.includes(:gesture).order(:position).map { |lp| lp.gesture.symbol }
  end
end
