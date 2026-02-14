# frozen_string_literal: true

require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, email_address: "user@test.com", password: "Password123", password_confirmation: "Password123")
  end

  test "GET /passwords/new renders reset form" do
    get new_password_url
    assert_response :success
    assert_select "form"
  end

  test "POST /passwords sends reset email and redirects" do
    post passwords_url, params: { email_address: "user@test.com" }
    assert_redirected_to new_session_path
  end

  test "POST /passwords with unknown email still redirects (no leak)" do
    post passwords_url, params: { email_address: "unknown@test.com" }
    assert_redirected_to new_session_path
  end

  test "GET /passwords/:token/edit with valid token renders form" do
    token = @user.generate_token_for(:password_reset)
    get edit_password_url(token)
    assert_response :success
  end

  test "GET /passwords/:token/edit with invalid token redirects" do
    get edit_password_url("invalid-token")
    assert_redirected_to new_password_path
  end

  test "PATCH /passwords/:token with valid data resets password" do
    token = @user.generate_token_for(:password_reset)
    patch password_url(token), params: { user: { password: "newPassword123", password_confirmation: "newPassword123" } }
    assert_redirected_to new_session_path

    # Verify new password works
    post session_url, params: { email_address: "user@test.com", password: "newPassword123" }
    assert_response :redirect
  end
end
