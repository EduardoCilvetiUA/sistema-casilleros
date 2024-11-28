class MetricsController < ApplicationController
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

  def calculate_weekly_usage
    (6.days.ago.to_date..Date.today).map do |date|
      events = LockerEvent.where(event_time: date.all_day)
      total_lockers = Locker.count
      usage = total_lockers > 0 ? (events.count.to_f / total_lockers * 100).round(2) : 0
      [date.strftime("%d/%m"), usage]
    end.to_h
  end

  def calculate_gesture_stats
    gestures = LockerPassword.joins(:gesture)
                            .group('gestures.name')
                            .count
    total = gestures.values.sum
    gestures.transform_values { |v| ((v.to_f / total) * 100).round(2) }
  end

  def calculate_failed_attempts
    LockerEvent.where(success: false)
               .joins(:locker)
               .group('lockers.number')
               .count
  end

  def calculate_hourly_pattern
    LockerEvent.where(
      event_time: 7.days.ago..Time.current
    ).group_by_hour_of_day(:event_time).count
  end

  def calculate_access_duration
    events = LockerEvent.where(
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
