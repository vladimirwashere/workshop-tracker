# frozen_string_literal: true

require "test_helper"

class CurrencyRatePolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can index currency rates" do
    assert CurrencyRatePolicy.new(@admin, CurrencyRate).index?
    assert CurrencyRatePolicy.new(@owner, CurrencyRate).index?
    assert CurrencyRatePolicy.new(@manager, CurrencyRate).index?
  end

  test "admin and manager can fetch latest rates" do
    assert CurrencyRatePolicy.new(@admin, CurrencyRate).fetch_latest?
    assert CurrencyRatePolicy.new(@manager, CurrencyRate).fetch_latest?
  end

  test "owner cannot fetch latest rates" do
    assert_not CurrencyRatePolicy.new(@owner, CurrencyRate).fetch_latest?
  end
end
