class WelcomeController < ApplicationController
  allow_unauthenticated_access only: %i[home script]
  protect_from_forgery except: :script
  layout "public"

  def home
    redirect_to authenticated? ? dashboard_path : announcements_path
  end

  def script
    render layout: false
  end
end
