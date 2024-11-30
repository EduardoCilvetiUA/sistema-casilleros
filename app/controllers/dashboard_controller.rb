class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_superuser
  
  def index
    @active_users = User.count
    @controllers = Controller.count
    @total_lockers = Locker.count
    @last_24h_openings = LockerEvent.where(
      event_type: 'open',
      event_time: 24.hours.ago..Time.current
    ).count

    # Daily openings for last 7 days
    @daily_openings = LockerEvent.where(
      event_type: 'open',
      event_time: 7.days.ago..Time.current
    ).group_by_day(:event_time)
     .count

    # Controller status with default values
    @controller_status = {
      true => Controller.where(is_connected: true).count,
      false => Controller.where(is_connected: false).count
    }

    # Hourly activity with all hours
    @hourly_activity = Hash.new(0).merge(
      LockerEvent.where(event_time: 7.days.ago..Time.current)
                 .group_by_hour_of_day(:event_time)
                 .count
    )

    # Access ratio with defaults
    @access_ratio = {
      true => LockerEvent.where(success: true, event_time: 7.days.ago..Time.current).count,
      false => LockerEvent.where(success: false, event_time: 7.days.ago..Time.current).count
    }
  end

  private

  def ensure_superuser
    unless current_user.is_superuser?
      redirect_to root_path
    end
  end
end