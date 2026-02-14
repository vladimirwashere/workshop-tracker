# frozen_string_literal: true

require "test_helper"

class TaskPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
    @task = create(:task)
  end

  test "all roles can index tasks" do
    assert TaskPolicy.new(@admin, @task).index?
    assert TaskPolicy.new(@owner, @task).index?
    assert TaskPolicy.new(@manager, @task).index?
  end

  test "all roles can show tasks" do
    assert TaskPolicy.new(@admin, @task).show?
    assert TaskPolicy.new(@owner, @task).show?
    assert TaskPolicy.new(@manager, @task).show?
  end

  test "admin and manager can create tasks, owner cannot" do
    assert TaskPolicy.new(@admin, @task).create?
    assert_not TaskPolicy.new(@owner, @task).create?
    assert TaskPolicy.new(@manager, @task).create?
  end

  test "admin and manager can update tasks, owner cannot" do
    assert TaskPolicy.new(@admin, @task).update?
    assert_not TaskPolicy.new(@owner, @task).update?
    assert TaskPolicy.new(@manager, @task).update?
  end

  test "admin and manager can destroy tasks, owner cannot" do
    assert TaskPolicy.new(@admin, @task).destroy?
    assert_not TaskPolicy.new(@owner, @task).destroy?
    assert TaskPolicy.new(@manager, @task).destroy?
  end

  test "scope returns kept tasks" do
    discarded = create(:task, :discarded)
    scope = TaskPolicy::Scope.new(@admin, Task).resolve
    assert_includes scope, @task
    assert_not_includes scope, discarded
  end
end
