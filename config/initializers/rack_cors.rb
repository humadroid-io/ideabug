# Parse CORS_ALLOWED_ORIGINS into an array of matchers rack-cors understands.
#
# Each comma-separated entry is either:
#   - "*"                 → allow any origin
#   - "https://foo.com"   → exact origin match (scheme required)
#   - "foo.com"           → exact host over http/https with optional port
#   - "*.foo.com"         → any subdomain of foo.com over http/https with optional port
#
# Unset or blank → API stays open to any origin (preserves prior behavior).
def parse_cors_origins(raw)
  entries = raw.to_s.split(",").map(&:strip).reject(&:empty?)
  return ["*"] if entries.empty? || entries.include?("*")

  entries.map do |entry|
    if entry.start_with?("http://", "https://")
      entry
    elsif entry.start_with?("*.")
      domain = Regexp.escape(entry.sub(/\A\*\./, ""))
      %r{\Ahttps?://[^/]+\.#{domain}(?::\d+)?\z}
    else
      host = Regexp.escape(entry)
      %r{\Ahttps?://#{host}(?::\d+)?\z}
    end
  end
end

api_origins = parse_cors_origins(ENV["CORS_ALLOWED_ORIGINS"])

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "localhost:3000", "127.0.0.1:3000", "ideabug.test"

    resource "*",
      methods: [:get, :post, :delete, :put, :patch, :options, :head],
      headers: :any
  end

  allow do
    origins "*"
    resource "/script.js",
      headers: :any,
      methods: :get
  end

  allow do
    origins(*api_origins)
    resource "/api/v1/*",
      headers: :any,
      methods: [:get, :post, :delete, :options],
      expose: %w[X-Ideabug-Unread X-Ideabug-Opted-Out X-Ideabug-Contact-Id X-Ideabug-Anonymous-Id]
  end
end
