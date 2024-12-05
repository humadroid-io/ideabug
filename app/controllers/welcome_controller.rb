class WelcomeController < ApplicationController
  protect_from_forgery except: :script
  layout "public"
  def home
  end

  def script
    render layout: false
  end
end
