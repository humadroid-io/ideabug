class ApplicationController < ActionController::Base
  include Authentication
  include Pagy::Backend

  def announcements_publicly_accessible?
    Rails.application.config.x.announcements_publicly_accessible
  end
  helper_method :announcements_publicly_accessible?
end
