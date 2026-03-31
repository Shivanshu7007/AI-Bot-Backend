class Rack::Attack
  # Throttle chat endpoint: 20 requests per minute per IP
  throttle("chat/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/chat" && req.post?
  end

  # Throttle all API endpoints: 60 requests per minute per IP
  throttle("api/ip", limit: 60, period: 1.minute) do |req|
    req.ip if req.path.start_with?("/api/")
  end

  # Return 429 with a meaningful message when throttled
  self.throttled_responder = lambda do |req|
    [
      429,
      { "Content-Type" => "application/json" },
      [{ error: "Too many requests. Please slow down." }.to_json]
    ]
  end
end
