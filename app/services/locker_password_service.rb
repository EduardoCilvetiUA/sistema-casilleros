class LockerPasswordService
  def self.update_password(locker, gesture_symbols)
    return false if gesture_symbols.blank? || gesture_symbols.length != 4

    # Obtener los gestos correspondientes a los símbolos
    gestures = locker.controller.model.gestures.where(symbol: gesture_symbols)
    return false if gestures.length != 4

    ActiveRecord::Base.transaction do
      # Eliminar las contraseñas anteriores
      locker.locker_passwords.destroy_all

      # Crear las nuevas contraseñas
      gesture_symbols.each_with_index do |symbol, index|
        gesture = gestures.find { |g| g.symbol == symbol }
        locker.locker_passwords.create!(
          gesture: gesture,
          position: index
        )
      end

      # Enviar email con la nueva contraseña
      LockerMailer.password_updated(locker).deliver_later

      true
    end
  rescue ActiveRecord::RecordInvalid
    false
  end
end