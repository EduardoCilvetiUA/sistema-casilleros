class MetricsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user_lockers
  
  def usage_stats
    @usage_data = calculate_weekly_usage
    @gesture_stats = calculate_gesture_stats
    @failed_attempts = calculate_failed_attempts
    @hourly_pattern = calculate_hourly_pattern
    @access_duration = calculate_access_duration
    
    # Calculate summary stats
    usage_by_day = @usage_data.values
    @peak_usage = usage_by_day.max
    @lowest_usage = usage_by_day.min
    @average_usage = (usage_by_day.sum / usage_by_day.size).round(2)
    @peak_day = @usage_data.key(@peak_usage)
    @lowest_day = @usage_data.key(@lowest_usage)
  end

  private
  
  def set_user_lockers
    if current_user.superuser?
      @user_lockers = Locker.all
    else
      @user_lockers = Locker.joins(:controller)
                           .where(controllers: { user_id: current_user.id })
    end
  end

  def calculate_weekly_usage
    (6.days.ago.to_date..Date.today).map do |date|
      events = LockerEvent.where(locker: @user_lockers, event_time: date.all_day)
      total_lockers = @user_lockers.count
      usage = total_lockers > 0 ? (events.count.to_f / total_lockers * 100).round(2) : 0
      [date.strftime("%d/%m"), usage]
    end.to_h
  end

  def calculate_gesture_stats
    gestures = LockerPassword.joins(:gesture, locker: :controller)
                            .where(lockers: { id: @user_lockers })
                            .group('gestures.name')
                            .count
    total = gestures.values.sum
    return {} if total.zero?
    gestures.transform_values { |v| ((v.to_f / total) * 100).round(2) }
  end

  def calculate_failed_attempts
    LockerEvent.where(success: false, locker: @user_lockers)
               .joins(:locker)
               .group('lockers.number')
               .count
  end

  def calculate_hourly_pattern
    LockerEvent.where(
      locker: @user_lockers,
      event_time: 7.days.ago..Time.current
    ).group_by_hour_of_day(:event_time).count
  end

  def calculate_access_duration
    events = LockerEvent.where(
      locker: @user_lockers,
      event_type: ['open', 'close'],
      event_time: 7.days.ago..Time.current
    ).order(:event_time)
    
    durations = []
    events.each_slice(2) do |open, close|
      next unless close && open.event_type == 'open' && close.event_type == 'close'
      durations << ((close.event_time - open.event_time) / 60).round
    end
    
    durations.group_by { |d| d / 15 * 15 }
            .transform_keys { |k| "#{k}-#{k + 15} min" }
            .transform_values(&:count)
  end
end