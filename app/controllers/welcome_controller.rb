class WelcomeController < ApplicationController
  allow_unauthenticated_access only: %i[home script]
  protect_from_forgery except: :script
  layout "public"

  def home
    return redirect_to dashboard_path if authenticated?
    return redirect_to public_announcements_path if announcements_publicly_accessible?
    # Otherwise render the marketing home view (welcome/home.html.erb).
  end

  def script
    render layout: false
  end
end
