# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/config/"
  add_filter "/vendor/"
  minimum_coverage 0
end

require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

WebMock.disable_net_connect!(allow_localhost: true)

module ConfigSetup
  def seed_configs
    Config.find_or_create_by!(key: "cas_rate") { |c| c.value = "0.25" }
    Config.find_or_create_by!(key: "cass_rate") { |c| c.value = "0.10" }
    Config.find_or_create_by!(key: "income_tax_rate") { |c| c.value = "0.10" }
    Config.find_or_create_by!(key: "default_vat_rate") { |c| c.value = "0.21" }
    Config.find_or_create_by!(key: "standard_hours_per_day") { |c| c.value = "8" }
  end
end

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  include ConfigSetup

  setup do
    seed_configs
  end
end

class ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods
  include ConfigSetup

  setup do
    seed_configs
  end

  private

  def setup_roles
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  def sign_in(user)
    post session_url, params: { email_address: user.email_address, password: "Password123" }
    assert_response :redirect
    follow_redirect!
  end

  def sign_out
    delete session_url
  end
end
