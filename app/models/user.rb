class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [ :google_oauth2 ]

  has_many :controllers

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image

      # Corregir la lista de emails de administradores
      admin_emails = [ "admin@example.com", "lalocilveti@gmail.com", "bjmanterola@miuandes.cl" ]
      user.is_superuser = admin_emails.include?(auth.info.email)
    end
  end

  def superuser?
    is_superuser == true
  end
end
