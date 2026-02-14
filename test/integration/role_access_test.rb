# frozen_string_literal: true

require "test_helper"

class RoleAccessTest < ActionDispatch::IntegrationTest
  setup do
    @admin = create(:user, :admin, password: "Password123", password_confirmation: "Password123")
    @owner = create(:user, :owner, password: "Password123", password_confirmation: "Password123")
    @manager = create(:user, :manager, password: "Password123", password_confirmation: "Password123")
  end

  # Dashboard access
  test "admin sees dashboard" do
    sign_in @admin
    get dashboard_url
    assert_response :success
  end

  test "owner sees dashboard" do
    sign_in @owner
    get dashboard_url
    assert_response :success
  end

  test "manager sees dashboard" do
    sign_in @manager
    get dashboard_url
    assert_response :success
  end

  # Account access (all roles)
  test "all roles can access account page" do
    [ @admin, @owner, @manager ].each do |user|
      sign_in user
      get account_url
      assert_response :success, "#{user.role} should access account page"
      sign_out
    end
  end

  # Health check (public)
  test "health check accessible without auth" do
    get rails_health_check_url
    assert_response :success
  end
end
