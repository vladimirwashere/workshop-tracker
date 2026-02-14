# frozen_string_literal: true

require "test_helper"

class ProjectTest < ActiveSupport::TestCase
  test "valid project" do
    project = build(:project)
    assert project.valid?
  end

  test "requires name" do
    project = build(:project, name: nil)
    assert_not project.valid?
  end

  test "requires planned_start_date" do
    project = build(:project, planned_start_date: nil)
    assert_not project.valid?
  end

  test "requires planned_end_date" do
    project = build(:project, planned_end_date: nil)
    assert_not project.valid?
  end

  test "end_date must be after start_date" do
    project = build(:project, planned_start_date: Date.current, planned_end_date: Date.current - 1.day)
    assert_not project.valid?
    assert_includes project.errors[:planned_end_date], "must be on or after the start date"
  end

  test "status enum values" do
    assert_equal 0, Project.statuses[:planned]
    assert_equal 1, Project.statuses[:active]
    assert_equal 2, Project.statuses[:completed]
    assert_equal 3, Project.statuses[:on_hold]
    assert_equal 4, Project.statuses[:cancelled]
  end

  test "cannot complete project with open tasks" do
    project = create(:project, :active)
    create(:task, project: project, status: :in_progress)

    project.status = :completed
    assert_not project.valid?
    assert_includes project.errors[:status], "cannot be completed while tasks are still open"
  end

  test "can complete project when all tasks done or cancelled" do
    project = create(:project, :active)
    create(:task, project: project, status: :done)
    create(:task, project: project, status: :cancelled)

    project.status = :completed
    assert project.valid?
  end

  test "active_projects scope excludes cancelled and discarded" do
    active = create(:project, :active)
    create(:project, :cancelled)
    create(:project, :discarded)

    result = Project.active_projects
    assert_includes result, active
  end

  test "soft delete with discard" do
    project = create(:project)
    project.discard
    assert project.discarded?
  end

  test "has many phases" do
    project = create(:project)
    create(:phase, project: project)
    create(:phase, project: project)
    assert_equal 2, project.phases.count
  end
end
