# frozen_string_literal: true

require "test_helper"

class PhaseTest < ActiveSupport::TestCase
  test "valid phase" do
    phase = build(:phase)
    assert phase.valid?
  end

  test "requires name" do
    phase = build(:phase, name: nil)
    assert_not phase.valid?
  end

  test "requires planned_start_date" do
    phase = build(:phase, planned_start_date: nil)
    assert_not phase.valid?
  end

  test "requires planned_end_date" do
    phase = build(:phase, planned_end_date: nil)
    assert_not phase.valid?
  end

  test "end_date must be after start_date" do
    project = create(:project, planned_start_date: Date.current, planned_end_date: Date.current + 30.days)
    phase = build(:phase, project: project, planned_start_date: Date.current + 5.days, planned_end_date: Date.current + 2.days)
    assert_not phase.valid?
    assert phase.errors[:planned_end_date].any?
  end

  test "phase dates must fall within project range" do
    project = create(:project, planned_start_date: Date.new(2026, 3, 1), planned_end_date: Date.new(2026, 3, 31))
    phase = build(:phase, project: project, planned_start_date: Date.new(2026, 2, 15), planned_end_date: Date.new(2026, 3, 15))
    assert_not phase.valid?
    assert phase.errors[:planned_start_date].any?
  end

  test "phase end date cannot exceed project end date" do
    project = create(:project, planned_start_date: Date.new(2026, 3, 1), planned_end_date: Date.new(2026, 3, 31))
    phase = build(:phase, project: project, planned_start_date: Date.new(2026, 3, 1), planned_end_date: Date.new(2026, 4, 15))
    assert_not phase.valid?
    assert phase.errors[:planned_end_date].any?
  end

  test "status enum values" do
    assert_equal 0, Phase.statuses[:planned]
    assert_equal 1, Phase.statuses[:in_progress]
    assert_equal 2, Phase.statuses[:done]
    assert_equal 3, Phase.statuses[:cancelled]
  end

  test "priority enum values" do
    assert_equal 0, Phase.priorities[:low]
    assert_equal 1, Phase.priorities[:medium]
    assert_equal 2, Phase.priorities[:high]
  end

  test "belongs to project" do
    project = create(:project)
    phase = create(:phase, project: project)
    assert_equal project.id, phase.project_id
  end

  test "has many tasks" do
    phase = create(:phase)
    create(:task, :with_phase, phase: phase)
    create(:task, :with_phase, phase: phase)
    assert_equal 2, phase.tasks.count
  end

  test "soft delete with discard" do
    phase = create(:phase)
    phase.discard
    assert phase.discarded?
  end
end
