# frozen_string_literal: true

require "test_helper"

class WorkerTest < ActiveSupport::TestCase
  test "valid worker" do
    worker = build(:worker)
    assert worker.valid?
  end

  test "requires full_name" do
    worker = build(:worker, full_name: nil)
    assert_not worker.valid?
    assert_includes worker.errors[:full_name], "can't be blank"
  end

  test "active_workers scope" do
    active = create(:worker, active: true)
    create(:worker, :inactive)
    create(:worker, :discarded)

    result = Worker.active_workers
    assert_includes result, active
    assert_equal 1, result.count
  end

  test "current_salary returns latest effective salary" do
    worker = create(:worker)
    old_salary = create(:worker_salary, worker: worker, gross_monthly_ron: 4000, effective_from: 1.year.ago)
    new_salary = create(:worker_salary, worker: worker, gross_monthly_ron: 5000, effective_from: 1.month.ago)

    assert_equal new_salary, worker.current_salary
    assert_equal old_salary, worker.current_salary(6.months.ago.to_date)
  end

  test "current_salary returns nil when no salary exists" do
    worker = create(:worker)
    assert_nil worker.current_salary
  end

  test "soft delete with discard" do
    worker = create(:worker)
    worker.discard
    assert worker.discarded?
  end
end
