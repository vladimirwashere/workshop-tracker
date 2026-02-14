# frozen_string_literal: true

require "test_helper"

class FXFetcherTest < ActiveSupport::TestCase
  test "returns error when no API key configured" do
    ENV.delete("EXCHANGERATE_API_KEY") if ENV["EXCHANGERATE_API_KEY"]

    fetcher = FXFetcher.new(api_key: nil)
    result = fetcher.fetch_and_store(date: Date.current)

    assert_not result.success?
    assert_match(/No API key/, result.error)
  end

  test "fetches and stores rate for today successfully" do
    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/pair/RON/GBP")
      .to_return(
        status: 200,
        body: { result: "success", conversion_rate: 0.1724 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    fetcher = FXFetcher.new(api_key: "test_api_key_123")
    result = fetcher.fetch_and_store(date: Date.current)

    assert result.success?
    assert_in_delta 0.1724, result.rate, 0.0001

    stored = CurrencyRate.find_by(date: Date.current)&.rate
    assert_in_delta 0.1724, stored, 0.0001
  end

  test "fetches historical rate for past date" do
    past_date = Date.new(2026, 1, 15)
    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/history/RON/GBP/2026/1/15")
      .to_return(
        status: 200,
        body: { result: "success", conversion_rate: 0.1698 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    fetcher = FXFetcher.new(api_key: "test_api_key_123")
    result = fetcher.fetch_and_store(date: past_date)

    assert result.success?
    assert_in_delta 0.1698, result.rate, 0.0001
  end

  test "handles API error response" do
    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/pair/RON/GBP")
      .to_return(
        status: 200,
        body: { result: "error", "error-type": "invalid-key" }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    fetcher = FXFetcher.new(api_key: "test_api_key_123")
    result = fetcher.fetch_and_store(date: Date.current)

    assert_not result.success?
    assert_match(/invalid-key/, result.error)
  end

  test "handles HTTP error with retry" do
    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/pair/RON/GBP")
      .to_return(status: 500, body: "Internal Server Error")
      .then
      .to_return(status: 500, body: "Internal Server Error")
      .then
      .to_return(status: 500, body: "Internal Server Error")

    fetcher = FXFetcher.new(api_key: "test_api_key_123")
    result = fetcher.fetch_and_store(date: Date.current)

    assert_not result.success?
    assert_match(/HTTP 500/, result.error)
  end

  test "handles timeout with retry" do
    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/pair/RON/GBP")
      .to_timeout

    fetcher = FXFetcher.new(api_key: "test_api_key_123")
    result = fetcher.fetch_and_store(date: Date.current)

    assert_not result.success?
    assert_match(/timeout/i, result.error)
  end

  test "updates existing rate for same date" do
    create(:currency_rate, date: Date.current, rate: 0.15)

    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/pair/RON/GBP")
      .to_return(
        status: 200,
        body: { result: "success", conversion_rate: 0.1724 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    fetcher = FXFetcher.new(api_key: "test_api_key_123")

    assert_no_difference "CurrencyRate.count" do
      result = fetcher.fetch_and_store(date: Date.current)
      assert result.success?
    end

    assert_in_delta 0.1724, CurrencyRate.find_by(date: Date.current)&.rate, 0.0001
  end

  test "does not store rate on API failure" do
    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_api_key_123/pair/RON/GBP")
      .to_return(status: 403, body: "Forbidden")

    fetcher = FXFetcher.new(api_key: "test_api_key_123")

    assert_no_difference "CurrencyRate.count" do
      fetcher.fetch_and_store(date: Date.current)
    end
  end
end
