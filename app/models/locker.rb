class Locker < ApplicationRecord
  belongs_to :controller
  has_many :locker_passwords
  has_many :gestures, through: :locker_passwords
  has_many :locker_events

  validates :number, presence: true
  validates :owner_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  # Método para obtener la contraseña del casillero
  def password
    locker_passwords.order(:position).map { |lp| lp.gesture.symbol }.join
  end
end