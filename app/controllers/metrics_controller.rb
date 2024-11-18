class MetricsController < ApplicationController
  def usage_stats
    # Calculate last 7 days stats
    @usage_data = calculate_weekly_usage
    @gesture_stats = calculate_gesture_stats
    @failed_attempts = calculate_failed_attempts
    
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
end
