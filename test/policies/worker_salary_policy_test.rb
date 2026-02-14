# frozen_string_literal: true

require "test_helper"

class WorkerSalaryPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "admin, owner, manager can index salaries" do
    assert WorkerSalaryPolicy.new(@admin, WorkerSalary).index?
    assert WorkerSalaryPolicy.new(@owner, WorkerSalary).index?
    assert WorkerSalaryPolicy.new(@manager, WorkerSalary).index?
  end

  test "admin and manager can create salaries" do
    assert WorkerSalaryPolicy.new(@admin, WorkerSalary).create?
    assert WorkerSalaryPolicy.new(@manager, WorkerSalary).create?
  end

  test "owner cannot create salaries" do
    assert_not WorkerSalaryPolicy.new(@owner, WorkerSalary).create?
  end

  test "scope returns kept salaries for authorized roles" do
    worker = create(:worker)
    salary = create(:worker_salary, worker: worker)
    discarded = create(:worker_salary, worker: worker, effective_from: 1.year.ago)
    discarded.discard

    admin_scope = WorkerSalaryPolicy::Scope.new(@admin, WorkerSalary).resolve
    assert_includes admin_scope, salary
    assert_not_includes admin_scope, discarded
  end
end
