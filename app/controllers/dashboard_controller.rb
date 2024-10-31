class DashboardController < ApplicationController
    before_action :authenticate_user!
    
    def index
      @active_users = User.count
      @controllers = Controller.count
      @total_lockers = Locker.count
      @last_24h_openings = Locker.where(updated_at: 24.hours.ago..Time.current).count
    end
  end