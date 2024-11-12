class LockerMailer < ApplicationMailer
  def password_updated(locker)
    @locker = locker
    # Obtener los símbolos de los gestos correctamente
    @gestures = @locker.password_sequence
    mail(
      to: @locker.owner_email,
      subject: "Actualización de Contraseña de Casillero")
  end

  def owner_updated(locker)
    @locker = locker
    @locker_password = @locker.password_sequence
    mail(
      to: @locker.owner_email,
      subject: "Propietario de Casillero Actualizado"
    )
  end
end
