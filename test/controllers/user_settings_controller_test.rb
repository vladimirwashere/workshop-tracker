# frozen_string_literal: true

require "test_helper"

class UserSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :admin, password: "Password123", password_confirmation: "Password123")
    sign_in @user
  end

  test "PATCH /user_settings updates currency preference" do
    patch user_settings_url, params: {
      user_setting: { default_currency_display: "GBP" }
    }
    assert_response :redirect
    @user.user_setting.reload
    assert_equal "GBP", @user.user_setting.default_currency_display
  end

  test "PATCH /user_settings returns json success for currency toggle" do
    patch user_settings_url,
      params: { user_setting: { default_currency_display: "GBP" } },
      headers: { "Accept" => "application/json" }

    assert_response :success

    payload = JSON.parse(response.body)
    assert_equal true, payload["ok"]
    assert_equal "GBP", payload["currency"]

    @user.user_setting.reload
    assert_equal "GBP", @user.user_setting.default_currency_display
  end

  test "PATCH /user_settings updates gantt zoom" do
    patch user_settings_url, params: {
      user_setting: { last_gantt_zoom: 14 }
    }
    assert_response :redirect
    @user.user_setting.reload
    assert_equal 14, @user.user_setting.last_gantt_zoom
  end

  test "requires authentication" do
    sign_out
    patch user_settings_url, params: { user_setting: { default_currency_display: "GBP" } }
    assert_redirected_to new_session_path
  end
end
