# frozen_string_literal: true

require "test_helper"

class DashboardPolicyTest < ActiveSupport::TestCase
  test "admin can view dashboard" do
    assert DashboardPolicy.new(create(:user, :admin), :dashboard).show?
  end

  test "owner can view dashboard" do
    assert DashboardPolicy.new(create(:user, :owner), :dashboard).show?
  end

  test "manager can view dashboard" do
    assert DashboardPolicy.new(create(:user, :manager), :dashboard).show?
  end
end
