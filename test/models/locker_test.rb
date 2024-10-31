require "test_helper"

class LockerTest < ActiveSupport::TestCase
  def setup
    @controller = controllers(:one)
    @locker = Locker.create!(
      number: 1,
      owner_email: "test@example.com",
      controller: @controller
    )
  end

  test "should verify correct password sequence" do
    model = Model.create!(name: "Test Model", file_path: "test.h5", size_bytes: 1000)
    gestures = 4.times.map do |i|
      Gesture.create!(name: "Gesture #{i}", symbol: "G#{i}", model: model)
    end
    
    gestures.each_with_index do |gesture, index|
      LockerPassword.create!(
        locker: @locker,
        gesture: gesture,
        position: index
      )
    end

    correct_sequence = gestures.map(&:symbol)
    assert @locker.verify_password(correct_sequence)
  end
end

# test/models/controller_test.rb
require "test_helper"

class ControllerTest < ActiveSupport::TestCase
  test "should detect inactive controllers" do
    controller = Controller.create!(
      name: "Test Controller",
      location: "Test Location",
      user: users(:one),
      model: models(:one),
      last_connection: 11.minutes.ago
    )

    assert controller.inactive?
  end
end
