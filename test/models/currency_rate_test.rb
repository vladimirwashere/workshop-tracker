# frozen_string_literal: true

require "test_helper"

class CurrencyRateTest < ActiveSupport::TestCase
  test "valid currency rate" do
    rate = build(:currency_rate)
    assert rate.valid?
  end

  test "requires date" do
    rate = build(:currency_rate, date: nil)
    assert_not rate.valid?
  end

  test "requires rate" do
    rate = build(:currency_rate, rate: nil)
    assert_not rate.valid?
  end

  test "rate must be positive" do
    rate = build(:currency_rate, rate: -1)
    assert_not rate.valid?
  end

  test "unique date per currency pair" do
    create(:currency_rate, date: Date.current)
    duplicate = build(:currency_rate, date: Date.current)
    assert_not duplicate.valid?
  end

  test "latest_rate returns most recent rate" do
    create(:currency_rate, date: Date.current - 1.day, rate: 0.16)
    create(:currency_rate, date: Date.current, rate: 0.17)

    assert_in_delta 0.17, CurrencyRate.latest_rate, 0.001
  end

  test "ron_to_gbp scope" do
    ron_gbp = create(:currency_rate, base_currency: "RON", quote_currency: "GBP")
    assert_includes CurrencyRate.ron_to_gbp, ron_gbp
  end
end
