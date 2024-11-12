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
  def status_notification(locker, status)
    @locker = locker
    @status = status
    @user_email = locker.owner_email

    mail(
      to: @user_email,
      subject: "Notificación de estado de tu casillero"
    )
  end
end
