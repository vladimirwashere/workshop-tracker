# frozen_string_literal: true

require "test_helper"

class ConfigsControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
  end

  # Index

  test "admin can list configs" do
    sign_in @admin
    get configs_url
    assert_response :success
  end

  test "manager can list configs" do
    sign_in @manager
    get configs_url
    assert_response :success
  end

  test "owner can list configs" do
    sign_in @owner
    get configs_url
    assert_response :success
  end

  # Update

  test "admin can update config" do
    config = Config.find_by(key: "default_vat_rate")
    sign_in @admin

    patch config_url(config), params: { config: { value: "0.09" } }
    assert_redirected_to configs_path

    config.reload
    assert_equal "0.09", config.value
  end

  test "manager can update config" do
    config = Config.find_by(key: "standard_hours_per_day")
    sign_in @manager

    patch config_url(config), params: { config: { value: "10" } }
    assert_redirected_to configs_path

    config.reload
    assert_equal "10", config.value
  end
end
