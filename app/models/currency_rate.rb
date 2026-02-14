# frozen_string_literal: true

class CurrencyRate < ApplicationRecord
  validates :date, presence: true
  validates :base_currency, presence: true
  validates :quote_currency, presence: true
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :date, uniqueness: { scope: %i[base_currency quote_currency] }

  scope :ron_to_gbp, -> { where(base_currency: "RON", quote_currency: "GBP") }

  def self.latest_rate(base: "RON", quote: "GBP")
    where(base_currency: base, quote_currency: quote).order(date: :desc).pick(:rate)
  end
end
