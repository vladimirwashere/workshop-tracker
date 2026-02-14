# frozen_string_literal: true

require "test_helper"

class CurrencyRatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @original_api_key = ENV["EXCHANGERATE_API_KEY"]
    ENV.delete("EXCHANGERATE_API_KEY")
  end

  teardown do
    ENV["EXCHANGERATE_API_KEY"] = @original_api_key
  end

  test "admin can view currency rates index" do
    create(:currency_rate, date: Date.current)
    sign_in @admin

    get currency_rates_url
    assert_response :success
  end

  test "owner can view currency rates" do
    sign_in @owner

    get currency_rates_url
    assert_response :success
  end

  test "manager can view currency rates" do
    sign_in @manager

    get currency_rates_url
    assert_response :success
  end

  test "admin can fetch latest rates" do
    ENV["EXCHANGERATE_API_KEY"] = "test_key"

    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_key/pair/RON/GBP")
      .to_return(
        status: 200,
        body: { result: "success", conversion_rate: 0.1724 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    sign_in @admin

    assert_difference "CurrencyRate.count" do
      post fetch_latest_currency_rates_url
    end

    assert_redirected_to currency_rates_path
    follow_redirect!
    assert_response :success
  end

  test "manager can fetch latest rates" do
    ENV["EXCHANGERATE_API_KEY"] = "test_key"

    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_key/pair/RON/GBP")
      .to_return(
        status: 200,
        body: { result: "success", conversion_rate: 0.1724 }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    sign_in @manager

    post fetch_latest_currency_rates_url
    assert_redirected_to currency_rates_path
  end

  test "owner cannot fetch rates" do
    sign_in @owner

    post fetch_latest_currency_rates_url
    assert_response :redirect
  end

  test "fetch_latest shows error on failure" do
    ENV["EXCHANGERATE_API_KEY"] = "test_key"

    stub_request(:get, "https://v6.exchangerate-api.com/v6/test_key/pair/RON/GBP")
      .to_return(status: 500, body: "Server Error")

    sign_in @admin

    post fetch_latest_currency_rates_url
    assert_redirected_to currency_rates_path
    follow_redirect!
    assert_select "div", /FX fetch failed/i
  end
end
