# frozen_string_literal: true

module AppConfig
  def self.get(key, default = nil)
    Config.get(key, default)
  rescue ActiveRecord::StatementInvalid
    default
  end

  def self.set(key, value)
    Config.set(key, value)
  end

  def self.default_vat_rate
    get("default_vat_rate", "0.21").to_d
  end

  def self.standard_hours_per_day
    get("standard_hours_per_day", "8").to_i
  end

  def self.fx_api_key
    ENV["EXCHANGERATE_API_KEY"].presence
  end

  def self.fx_api_provider
    get("fx_api_provider", "exchangerate_api")
  end
end
