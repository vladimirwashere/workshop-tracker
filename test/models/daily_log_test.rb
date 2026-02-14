# frozen_string_literal: true

require "test_helper"

class DailyLogTest < ActiveSupport::TestCase
  setup do
    @project = create(:project)
    @task = create(:task, project: @project)
    @worker = create(:worker)
    @user = create(:user)
  end

  test "valid daily log" do
    log = build(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @user)
    assert log.valid?
  end

  test "requires log_date" do
    log = build(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @user, log_date: nil)
    assert_not log.valid?
  end

  test "hours_worked defaults to 8 when blank" do
    log = build(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @user, hours_worked: nil)
    log.valid?
    assert_equal 8.0, log.hours_worked
  end

  test "hours_worked cannot be negative" do
    log = build(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @user, hours_worked: -1)
    assert_not log.valid?
  end

  test "in_range scope" do
    log = create(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @user, log_date: Date.current)
    create(:daily_log, project: @project, task: @task, worker: create(:worker), created_by_user: @user, log_date: Date.current - 60.days)

    result = DailyLog.in_range(Date.current - 7.days, Date.current)
    assert_includes result, log
    assert_equal 1, result.count
  end

  test "soft delete with discard" do
    log = create(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @user)
    log.discard
    assert log.discarded?
  end
end
