allowed_origins = [ENV.fetch("FRONTEND_URL", "http://localhost:3000")]

# Allow localhost variants in development so the React dev server can hit Rails
if Rails.env.development?
  allowed_origins += [
    "http://localhost:3000",
    "http://localhost:3001",
    "http://127.0.0.1:3000",
    "http://127.0.0.1:3001"
  ]
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins(*allowed_origins.uniq)

    resource "/chat",
      headers: :any,
      methods: [:post, :options]

    resource "/api/*",
      headers: :any,
      methods: [:get, :options]
  end
end