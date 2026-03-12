Rack::Attack.throttle("api/ip", limit: 300, period: 5.minutes) do |req|
  req.ip if req.path.start_with?("/api/")
end

Rack::Attack.throttle("api/auth", limit: 10, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api/v1/auth")
end
