# frozen_string_literal: true

require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @other_user = create(:user, :manager)
  end

  # Index

  test "admin can list users" do
    sign_in @admin
    get users_url
    assert_response :success
  end

  test "non-admin cannot list users" do
    sign_in @owner
    get users_url
    assert_redirected_to root_path
  end

  # Create

  test "admin can create user with valid params" do
    sign_in @admin

    assert_difference "User.count", 1 do
      post users_url, params: {
        user: {
          display_name: "New User",
          email_address: "newuser@example.com",
          password: "Password123",
          password_confirmation: "Password123",
          role: "owner"
        }
      }
    end

    assert_redirected_to users_path
    created = User.find_by(email_address: "newuser@example.com")
    assert_equal "owner", created.role
  end

  # Edit / Update

  test "admin can access edit page" do
    sign_in @admin
    get edit_user_url(@other_user)
    assert_response :success
  end

  test "admin can update user" do
    sign_in @admin
    patch user_url(@other_user), params: { user: { role: "owner" } }
    assert_redirected_to users_path

    @other_user.reload
    assert_equal "owner", @other_user.role
  end

  # Deactivate / Reactivate

  test "admin can deactivate user" do
    sign_in @admin
    patch deactivate_user_url(@other_user)
    assert_redirected_to users_path

    @other_user.reload
    assert_not @other_user.active
  end

  test "admin can reactivate user" do
    @other_user.update!(active: false)
    sign_in @admin
    patch reactivate_user_url(@other_user)
    assert_redirected_to users_path

    @other_user.reload
    assert @other_user.active
  end

  # Soft Delete

  test "admin can soft delete user" do
    sign_in @admin
    delete soft_delete_user_url(@other_user)
    assert_redirected_to users_path

    @other_user.reload
    assert_not_nil @other_user.discarded_at
  end

  # Reset Password

  test "admin can reset password" do
    sign_in @admin
    post reset_password_user_url(@other_user)
    assert_redirected_to users_path
  end
end
