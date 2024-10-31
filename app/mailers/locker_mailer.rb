class LockerMailer < ApplicationMailer
    def password_updated(locker)
      @locker = locker
      @password_sequence = locker.password_sequence.map { |lp| lp.gesture.name }.join(", ")
      
      mail(
        to: @locker.owner_email,
        subject: "Tu contraseña de casillero ha sido actualizada"
      )
    end
  end
  
  