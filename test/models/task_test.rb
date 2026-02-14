# frozen_string_literal: true

require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid task" do
    task = build(:task)
    assert task.valid?
  end

  test "requires name" do
    task = build(:task, name: nil)
    assert_not task.valid?
  end

  test "requires planned_start_date" do
    task = build(:task, planned_start_date: nil)
    assert_not task.valid?
  end

  test "requires planned_end_date" do
    task = build(:task, planned_end_date: nil)
    assert_not task.valid?
  end

  test "end_date must be after start_date" do
    task = build(:task, planned_start_date: Date.current, planned_end_date: Date.current - 1.day)
    assert_not task.valid?
  end

  test "task dates must fall within project range" do
    project = create(:project, planned_start_date: Date.new(2026, 3, 1), planned_end_date: Date.new(2026, 3, 31))

    task = build(:task, project: project, planned_start_date: Date.new(2026, 2, 15), planned_end_date: Date.new(2026, 3, 15))
    assert_not task.valid?
    assert task.errors[:planned_start_date].any?
  end

  test "task end date cannot exceed project end date" do
    project = create(:project, planned_start_date: Date.new(2026, 3, 1), planned_end_date: Date.new(2026, 3, 31))

    task = build(:task, project: project, planned_start_date: Date.new(2026, 3, 15), planned_end_date: Date.new(2026, 4, 15))
    assert_not task.valid?
    assert task.errors[:planned_end_date].any?
  end

  test "status enum values" do
    assert_equal 0, Task.statuses[:planned]
    assert_equal 1, Task.statuses[:in_progress]
    assert_equal 2, Task.statuses[:done]
    assert_equal 3, Task.statuses[:cancelled]
  end

  test "priority enum values" do
    assert_equal 0, Task.priorities[:low]
    assert_equal 1, Task.priorities[:medium]
    assert_equal 2, Task.priorities[:high]
  end

  test "soft delete with discard" do
    task = create(:task)
    task.discard
    assert task.discarded?
  end

  test "task can belong to phase optionally" do
    task = create(:task, :with_phase)
    assert task.phase_id.present?
    assert task.phase.present?
    assert_equal task.project_id, task.phase.project_id
  end

  test "task dates must fall within phase range when phase present" do
    project = create(:project, planned_start_date: Date.new(2026, 3, 1), planned_end_date: Date.new(2026, 3, 31))
    phase = create(:phase, project: project, planned_start_date: Date.new(2026, 3, 10), planned_end_date: Date.new(2026, 3, 20))
    task = build(:task, project: project, phase: phase,
      planned_start_date: Date.new(2026, 3, 5), planned_end_date: Date.new(2026, 3, 15))
    assert_not task.valid?
    assert task.errors[:planned_start_date].any?
  end

  test "phase_id must belong to same project" do
    project1 = create(:project)
    project2 = create(:project)
    phase2 = create(:phase, project: project2)
    task = build(:task, project: project1, phase: phase2,
      planned_start_date: project1.planned_start_date, planned_end_date: project1.planned_start_date + 5.days)
    assert_not task.valid?
    assert task.errors[:phase_id].any?
  end
end
