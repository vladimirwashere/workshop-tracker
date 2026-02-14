# frozen_string_literal: true

require "test_helper"

class FetchFXRatesJobTest < ActiveSupport::TestCase
  setup do
    @original_api_key = ENV["EXCHANGERATE_API_KEY"]
    ENV.delete("EXCHANGERATE_API_KEY")
  end

  teardown do
    ENV["EXCHANGERATE_API_KEY"] = @original_api_key
  end

  test "performs successfully with valid API response" do
    ENV["EXCHANGERATE_API_KEY"] = "test_key"

    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_key/pair/RON/GBP")
      .to_return(
        status: 200,
        body: { result: "success", conversion_rate: 0.1724 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_difference "CurrencyRate.count", 1 do
      FetchFXRatesJob.perform_now(date: Date.current)
    end
  end

  test "raises on failure so Solid Queue can track it" do
    ENV["EXCHANGERATE_API_KEY"] = "test_key"

    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_key/pair/RON/GBP")
      .to_return(status: 500, body: "Server Error")

    assert_raises(RuntimeError) do
      FetchFXRatesJob.perform_now(date: Date.current)
    end

    assert_equal 0, CurrencyRate.where(date: Date.current).count
  end
end
