class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:google_oauth2]

  def self.from_omniauth(auth)
    user = User.where(email: auth.info.email).first
    
    unless user
      user = User.create!(
        provider: auth.provider,
        uid: auth.uid,
        email: auth.info.email,
        password: Devise.friendly_token[0, 20],
        name: auth.info.name,
        avatar_url: auth.info.image
      )
    end

    user
  end
end