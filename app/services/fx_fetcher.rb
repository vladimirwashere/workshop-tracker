# frozen_string_literal: true

require "net/http"
require "json"

# Fetches RON/GBP exchange rates from ExchangeRate-API.
# Uses the "latest" endpoint for today's rate or "historical" for past dates.
# API docs: https://www.exchangerate-api.com/docs/pair-conversion-requests
#
# Configuration:
#   - ENV["EXCHANGERATE_API_KEY"]
#   - Config key "fx_api_provider" (currently only "exchangerate_api" supported)
class FXFetcher
  BASE_URL = "https://v6.exchangerate-api.com/v6".freeze
  MAX_RETRIES = 3
  INITIAL_BACKOFF = 1 # seconds

  class FetchError < StandardError; end
  class ConfigurationError < StandardError; end

  Result = Struct.new(:success?, :rate, :error, keyword_init: true)

  def initialize(api_key: nil)
    @api_key = api_key || resolve_api_key
  end

  # Fetches the RON -> GBP rate for a given date and stores it.
  # Returns a Result struct.
  def fetch_and_store(date: Date.current)
    validate_configuration!

    rate_value = fetch_rate(date)

    record = CurrencyRate.find_or_initialize_by(
      date: date,
      base_currency: "RON",
      quote_currency: "GBP"
    )
    record.rate = rate_value
    record.source = "exchangerate_api"
    record.save!

    Rails.logger.info("[FxFetcher] Stored rate for #{date}: RON/GBP = #{rate_value}")
    Result.new(success?: true, rate: rate_value)
  rescue FetchError, ConfigurationError => e
    Rails.logger.error("[FxFetcher] #{e.class}: #{e.message}")
    Result.new(success?: false, error: e.message)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[FxFetcher] Failed to save rate: #{e.message}")
    Result.new(success?: false, error: "Failed to save rate: #{e.message}")
  end

  private

  def resolve_api_key
    AppConfig.fx_api_key
  end

  def validate_configuration!
    raise ConfigurationError, "No API key configured. Set EXCHANGERATE_API_KEY environment variable." if @api_key.blank?
  end

  # Fetches the exchange rate with retry and exponential backoff.
  # ExchangeRate-API returns rates relative to a base currency.
  # We request pair conversion: RON -> GBP.
  def fetch_rate(date)
    url = build_url(date)
    attempt = 0

    begin
      attempt += 1
      response = make_request(url)
      parse_rate(response)
    rescue FetchError => e
      if attempt < MAX_RETRIES
        wait = INITIAL_BACKOFF * (2**(attempt - 1))
        Rails.logger.warn("[FxFetcher] Attempt #{attempt} failed: #{e.message}. Retrying in #{wait}s...")
        sleep(wait)
        retry
      end
      raise
    end
  end

  def build_url(date)
    if date == Date.current
      "#{BASE_URL}/#{@api_key}/pair/RON/GBP"
    else
      formatted = date.strftime("%Y/%-m/%-d")
      "#{BASE_URL}/#{@api_key}/history/RON/GBP/#{formatted}"
    end
  end

  def make_request(url)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 10
    http.read_timeout = 10

    request = Net::HTTP::Get.new(uri)
    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      raise FetchError, "HTTP #{response.code}: #{response.body.truncate(200)}"
    end

    JSON.parse(response.body)
  rescue JSON::ParserError => e
    raise FetchError, "Invalid JSON response: #{e.message}"
  rescue Net::OpenTimeout, Net::ReadTimeout => e
    raise FetchError, "Request timeout: #{e.message}"
  rescue SocketError, Errno::ECONNREFUSED => e
    raise FetchError, "Connection error: #{e.message}"
  end

  def parse_rate(data)
    unless data["result"] == "success"
      error_type = data["error-type"] || "unknown"
      raise FetchError, "API error: #{error_type}"
    end

    rate = data["conversion_rate"]
    raise FetchError, "No conversion_rate in response" if rate.nil?
    raise FetchError, "Invalid rate value: #{rate}" unless rate.is_a?(Numeric) && rate > 0

    rate.to_d
  end
end
