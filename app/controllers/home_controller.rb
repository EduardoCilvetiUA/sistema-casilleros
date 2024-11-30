class HomeController < ApplicationController
  def index
    if user_signed_in?
      if current_user.is_superuser?
        redirect_to dashboard_path
      else
        redirect_to controllers_path
      end
    end
  end
end