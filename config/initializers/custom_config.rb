Rails.configuration.x.tap do |x|
  x.announcements_publicly_accessible = ENV.fetch("ANNOUNCEMENTS_PUBLICLY_ACCESSIBLE", false)
end
