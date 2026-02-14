# frozen_string_literal: true

require "test_helper"

class GanttPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "admin can view and update gantt" do
    assert GanttPolicy.new(@admin, :gantt).show?
    assert GanttPolicy.new(@admin, :gantt).update?
  end

  test "owner can view gantt but cannot update" do
    assert GanttPolicy.new(@owner, :gantt).show?
    assert_not GanttPolicy.new(@owner, :gantt).update?
  end

  test "manager can view and update gantt" do
    assert GanttPolicy.new(@manager, :gantt).show?
    assert GanttPolicy.new(@manager, :gantt).update?
  end
end
