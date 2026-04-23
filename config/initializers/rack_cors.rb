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
    origins "*"
    resource "/api/v1/*",
      headers: :any,
      methods: [:get, :post, :delete, :options],
      expose: %w[X-Ideabug-Unread X-Ideabug-Opted-Out X-Ideabug-Contact-Id X-Ideabug-Anonymous-Id]
  end
end
