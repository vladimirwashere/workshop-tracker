# frozen_string_literal: true

require "test_helper"

class AuthJourneyTest < ActionDispatch::IntegrationTest
  test "admin login redirects to dashboard" do
    admin = create(:user, :admin, password: "Password123", password_confirmation: "Password123")
    sign_in admin
    assert_select "h1", /Dashboard/i
  end

  test "owner login redirects to dashboard" do
    owner = create(:user, :owner, password: "Password123", password_confirmation: "Password123")
    post session_url, params: { email_address: owner.email_address, password: "Password123" }
    assert_redirected_to dashboard_path
  end

  test "manager login redirects to dashboard" do
    manager = create(:user, :manager, password: "Password123", password_confirmation: "Password123")
    post session_url, params: { email_address: manager.email_address, password: "Password123" }
    assert_redirected_to dashboard_path
  end

  test "unauthenticated access stores return URL" do
    admin = create(:user, :admin, password: "Password123", password_confirmation: "Password123")

    # Try to access a protected page
    get account_url
    assert_redirected_to new_session_path

    # Log in, should redirect to originally requested page
    post session_url, params: { email_address: admin.email_address, password: "Password123" }
    assert_redirected_to account_url
  end

  test "full sign in - change settings - sign out flow" do
    user = create(:user, :admin, password: "Password123", password_confirmation: "Password123")

    # Sign in
    post session_url, params: { email_address: user.email_address, password: "Password123" }
    follow_redirect!
    assert_response :success

    # Change currency preference
    patch user_settings_url, params: { user_setting: { default_currency_display: "GBP" } }
    assert_response :redirect

    # Visit account page
    get account_url
    assert_response :success

    # Sign out
    delete session_url
    assert_redirected_to new_session_path
    follow_redirect!
    assert_response :success

    # Confirm signed out
    get dashboard_url
    assert_redirected_to new_session_path
  end

  test "password reset full flow" do
    user = create(:user, :admin, password: "Password123", password_confirmation: "Password123")

    # Request reset
    post passwords_url, params: { email_address: user.email_address }
    assert_redirected_to new_session_path

    # Use token to reset
    token = user.generate_token_for(:password_reset)
    get edit_password_url(token)
    assert_response :success

    patch password_url(token), params: { user: { password: "BrandNew123", password_confirmation: "BrandNew123" } }
    assert_redirected_to new_session_path

    # Log in with new password
    post session_url, params: { email_address: user.email_address, password: "BrandNew123" }
    assert_redirected_to dashboard_path
  end

  test "account update full flow" do
    user = create(:user, :admin, password: "Password123", password_confirmation: "Password123")
    sign_in user

    # Update email
    patch account_url, params: {
      current_password: "Password123",
      user: { email_address: "newemail@test.com" }
    }
    assert_redirected_to account_path

    # Verify can log in with new email
    delete session_url
    post session_url, params: { email_address: "newemail@test.com", password: "Password123" }
    assert_redirected_to dashboard_path
  end
end
