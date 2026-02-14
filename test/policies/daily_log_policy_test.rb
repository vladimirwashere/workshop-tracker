# frozen_string_literal: true

require "test_helper"

class DailyLogPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can index daily logs" do
    assert DailyLogPolicy.new(@admin, DailyLog).index?
    assert DailyLogPolicy.new(@owner, DailyLog).index?
    assert DailyLogPolicy.new(@manager, DailyLog).index?
  end

  test "admin and manager can create daily logs, owner cannot" do
    assert DailyLogPolicy.new(@admin, DailyLog).create?
    assert_not DailyLogPolicy.new(@owner, DailyLog).create?
    assert DailyLogPolicy.new(@manager, DailyLog).create?
  end

  test "admin and manager can update daily logs, owner cannot" do
    daily_log = create(:daily_log)
    assert DailyLogPolicy.new(@admin, daily_log).update?
    assert_not DailyLogPolicy.new(@owner, daily_log).update?
    assert DailyLogPolicy.new(@manager, daily_log).update?
  end

  test "admin and manager can destroy daily logs, owner cannot" do
    daily_log = create(:daily_log)
    assert DailyLogPolicy.new(@admin, daily_log).destroy?
    assert_not DailyLogPolicy.new(@owner, daily_log).destroy?
    assert DailyLogPolicy.new(@manager, daily_log).destroy?
  end
end
