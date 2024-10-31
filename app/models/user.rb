class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :controllers

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.name = auth.info.name
      user.avatar_url = auth.info.image
      
      # Lista de emails que serán superusuarios
      admin_emails = ['admin@example.com']
      user.is_superuser = admin_emails.include?(auth.info.email)
    end
  end

  def superuser?
    is_superuser == true
  end
end