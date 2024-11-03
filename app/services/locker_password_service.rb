class LockerPasswordService
  def self.update_password(locker, gesture_symbols)
    return false if gesture_symbols.blank? || gesture_symbols.length != 4

    # Fetch gestures based on symbols, handling duplicates and preserving order
    gestures = gesture_symbols.map do |symbol|
      locker.controller.model.gestures.find_by(symbol: symbol)
    end

    # Ensure all gestures were found
    return false if gestures.include?(nil)

    # Update locker passwords within a transaction
    LockerPassword.transaction do
      locker.locker_passwords.destroy_all
      gestures.each_with_index do |gesture, index|
        locker.locker_passwords.create!(
          gesture: gesture,
          position: index
        )
      end
    end
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end