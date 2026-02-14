# frozen_string_literal: true

require "test_helper"

class ReportPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "admin can access financial reports" do
    assert ReportPolicy.new(@admin, :report).financial?
  end

  test "owner can access financial reports" do
    assert ReportPolicy.new(@owner, :report).financial?
  end

  test "manager can access financial reports" do
    assert ReportPolicy.new(@manager, :report).financial?
  end

  test "admin can access activity reports" do
    assert ReportPolicy.new(@admin, :report).activity?
  end

  test "owner can access activity reports" do
    assert ReportPolicy.new(@owner, :report).activity?
  end

  test "manager can access activity reports" do
    assert ReportPolicy.new(@manager, :report).activity?
  end
end
