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
    resource "/tickets*",
      headers: :any,
      methods: :get
  end
end
