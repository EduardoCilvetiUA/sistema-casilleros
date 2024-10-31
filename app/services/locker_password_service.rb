class LockerPasswordService
    def self.update_password(locker, gesture_symbols)
      return false unless gesture_symbols.length == 4
      
      ActiveRecord::Base.transaction do
        locker.locker_passwords.destroy_all
        
        gesture_symbols.each_with_index do |symbol, index|
          gesture = Gesture.find_by!(symbol: symbol)
          LockerPassword.create!(
            locker: locker,
            gesture: gesture,
            position: index
          )
        end
  
        # Enviar email al dueño con la nueva contraseña
        LockerMailer.password_updated(locker).deliver_later
      end
      
      true
    rescue ActiveRecord::RecordNotFound => e
      false
    end
  end
  