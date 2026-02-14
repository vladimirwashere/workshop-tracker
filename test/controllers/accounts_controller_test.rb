# frozen_string_literal: true

require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user, :admin, email_address: "me@test.com", password: "Password123", password_confirmation: "Password123")
    sign_in @user
  end

  test "GET /account shows account page" do
    get account_url
    assert_response :success
  end

  test "PATCH /account updates email with correct current password" do
    patch account_url, params: {
      current_password: "Password123",
      user: { email_address: "newemail@test.com" }
    }
    assert_redirected_to account_path
    @user.reload
    assert_equal "newemail@test.com", @user.email_address
  end

  test "PATCH /account updates password with correct current password" do
    patch account_url, params: {
      current_password: "Password123",
      user: { password: "NewPassword1", password_confirmation: "NewPassword1" }
    }
    assert_redirected_to account_path
    @user.reload
    assert @user.authenticate("NewPassword1")
  end

  test "PATCH /account updates display_name without current password" do
    patch account_url, params: {
      user: { display_name: "New Name" }
    }
    assert_redirected_to account_path
    @user.reload
    assert_equal "New Name", @user.display_name
  end

  test "PATCH /account rejects email change without current password" do
    patch account_url, params: {
      user: { email_address: "newemail@test.com" }
    }
    assert_response :unprocessable_entity
  end

  test "PATCH /account rejects with wrong current password" do
    patch account_url, params: {
      current_password: "wrongpassword",
      user: { email_address: "newemail@test.com" }
    }
    assert_response :unprocessable_entity
  end

  test "requires authentication" do
    sign_out
    get account_url
    assert_redirected_to new_session_path
  end
end
