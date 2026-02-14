# frozen_string_literal: true

FactoryBot.define do
  factory :currency_rate do
    date { Date.current }
    base_currency { "RON" }
    quote_currency { "GBP" }
    rate { 0.17 }
    source { "exchangerate_api" }
  end
end
