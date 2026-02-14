# frozen_string_literal: true

# Rate limiting and request throttling.
# Applies in all environments. Limits are generous for normal use;
# they exist to prevent abuse, not restrict legitimate users.

class Rack::Attack
  # Disable in test environment
  Rack::Attack.enabled = !Rails.env.test?
  # Use Rails cache store for tracking
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # General request throttle: 300 requests per 5 minutes per IP
  throttle("req/ip", limit: 300, period: 5.minutes) do |req|
    req.ip unless req.path.start_with?("/assets", "/up")
  end

  # Login throttle: 10 attempts per 15 minutes per IP
  throttle("logins/ip", limit: 10, period: 15.minutes) do |req|
    req.ip if req.path == "/session" && req.post?
  end

  # Login throttle: 10 attempts per 15 minutes per email
  throttle("logins/email", limit: 10, period: 15.minutes) do |req|
    if req.path == "/session" && req.post?
      req.params.dig("email_address")&.downcase&.strip
    end
  end

  # Password reset throttle: 5 per hour per IP
  throttle("passwords/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.path == "/passwords" && req.post?
  end

  # Custom throttled response
  self.throttled_responder = lambda do |_req|
    [ 429, { "Content-Type" => "text/plain" }, [ "Rate limit exceeded. Retry later.\n" ] ]
  end
end
