# frozen_string_literal: true

require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin, email_address: "admin@test.com", password: "Password123", password_confirmation: "Password123")
  end

  test "GET /session/new renders login form" do
    get new_session_url
    assert_response :success
    assert_select "form"
  end

  test "POST /session with valid credentials signs in" do
    post session_url, params: { email_address: "admin@test.com", password: "Password123" }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  test "POST /session with invalid credentials shows error" do
    post session_url, params: { email_address: "admin@test.com", password: "wrongpassword" }
    assert_response :unprocessable_entity
  end

  test "POST /session with inactive user rejects login" do
    @admin.update!(active: false)
    post session_url, params: { email_address: "admin@test.com", password: "Password123" }
    assert_response :unprocessable_entity
  end

  test "POST /session with discarded user rejects login" do
    @admin.discard
    post session_url, params: { email_address: "admin@test.com", password: "Password123" }
    assert_response :unprocessable_entity
  end

  test "DELETE /session signs out" do
    sign_in @admin
    delete session_url
    assert_redirected_to new_session_path

    # Verify we're actually signed out by trying to access protected page
    get dashboard_url
    assert_redirected_to new_session_path
  end

  test "root path redirects to login" do
    get root_url
    assert_response :success # root IS the login page
  end
end
