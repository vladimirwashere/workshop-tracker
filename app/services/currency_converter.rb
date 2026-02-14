# frozen_string_literal: true

module CurrencyConverter
  def self.convert(amount_ron, currency:)
    value = amount_ron.to_d
    return value if currency == "RON"

    rate = CurrencyRate.latest_rate
    return nil if rate.nil? || rate.zero?

    (value * rate).round(2)
  end
end
