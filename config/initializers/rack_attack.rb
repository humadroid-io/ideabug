class Rack::Attack
  ANON_HEADER = "HTTP_X_IDEABUG_ANON_ID".freeze

  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  throttle("api/v1/tickets create per anon", limit: 5, period: 10.minutes) do |req|
    if req.post? && req.path == "/api/v1/tickets"
      req.env[ANON_HEADER].presence
    end
  end

  throttle("api/v1/tickets create per ip", limit: 20, period: 1.hour) do |req|
    if req.post? && req.path == "/api/v1/tickets"
      req.ip
    end
  end

  throttle("api/v1/tickets vote per anon", limit: 60, period: 1.hour) do |req|
    if req.post? && req.path =~ %r{\A/api/v1/tickets/\d+/vote\z}
      req.env[ANON_HEADER].presence
    end
  end

  throttle("api/v1/announcements read_all per anon", limit: 10, period: 1.hour) do |req|
    if req.post? && req.path == "/api/v1/announcements/read_all"
      req.env[ANON_HEADER].presence
    end
  end

  self.throttled_responder = ->(req) {
    match_data = req.env["rack.attack.match_data"] || {}
    headers = {
      "Content-Type" => "application/json",
      "Retry-After" => match_data[:period].to_s
    }
    [429, headers, [{error: "Rate limit exceeded"}.to_json]]
  }
end
