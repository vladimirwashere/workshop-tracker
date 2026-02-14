# frozen_string_literal: true

require "test_helper"

class ReportGeneratorTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @project = create(:project, :active, created_by_user: @admin)
    @task = create(:task, project: @project)
    @worker = create(:worker)
    create(:worker_salary, worker: @worker, gross_monthly_ron: 6000, effective_from: 1.year.ago)

    @log = create(:daily_log, project: @project, task: @task, worker: @worker,
                  created_by_user: @admin, hours_worked: 8, log_date: Date.current)

    @material = create(:material_entry, project: @project, task: @task, created_by_user: @admin,
                       date: Date.current, description: "Plywood", quantity: 5, unit: "sheet",
                       unit_cost_ex_vat_ron: 100, vat_rate: 0.21)

    @generator = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s
    )
  end

  test "labour_by_project returns project data" do
    result = @generator.labour_by_project
    assert_equal 1, result.length

    row = result.first
    assert_equal @project, row[:project]
    assert_equal 1, row[:total_days]
    assert row[:total_cost_ron] > 0
    assert_equal 1, row[:workers].length
  end

  test "labour_summary returns summary" do
    result = @generator.labour_summary
    assert_equal 1, result.length
    assert_equal @project, result.first[:project]
  end

  test "materials_by_project returns material data" do
    result = @generator.materials_by_project
    assert_equal 1, result.length

    row = result.first
    assert_equal @project, row[:project]
    assert_equal 500.0, row[:total_ex_vat_ron]
    assert_equal 105.0, row[:total_vat_ron]
    assert_equal 605.0, row[:total_inc_vat_ron]
  end

  test "combined_cost aggregates labour and materials" do
    result = @generator.combined_cost
    assert_equal 1, result.length

    row = result.first
    assert row[:labour_cost_ron] > 0
    assert_equal 500.0, row[:materials_ex_vat_ron]
    assert row[:total_ron] > 0
  end

  test "dashboard_kpis returns all KPI data" do
    kpis = @generator.dashboard_kpis
    assert kpis[:total_labour_ron] > 0
    assert_equal 605.0, kpis[:total_materials_ron]
    assert kpis[:total_combined_ron] > 0
    assert_equal 8.0, kpis[:total_hours]
    assert kpis[:top_projects].length <= 5
  end

  test "filters by project_ids" do
    other_project = create(:project, :active, created_by_user: @admin)
    other_task = create(:task, project: other_project)
    create(:daily_log, project: other_project, task: other_task, worker: @worker,
           created_by_user: @admin, hours_worked: 4, log_date: Date.current)

    gen = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s,
      project_ids: [ @project.id.to_s ]
    )

    result = gen.labour_by_project
    assert_equal 1, result.length
    assert_equal @project, result.first[:project]
  end

  test "filters by worker_ids" do
    other_worker = create(:worker)
    create(:worker_salary, worker: other_worker, gross_monthly_ron: 4000, effective_from: 1.year.ago)
    create(:daily_log, project: @project, task: @task, worker: other_worker,
           created_by_user: @admin, hours_worked: 6, log_date: Date.current)

    gen = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s,
      worker_ids: [ @worker.id.to_s ]
    )

    result = gen.labour_by_project
    assert_equal 1, result.length
    assert_equal @project, result.first[:project]
  end

  test "filters labour by phase_ids through tasks" do
    phase = create(:phase, project: @project)
    in_phase_task = create(:task, project: @project, phase: phase)
    out_phase_task = create(:task, project: @project, phase_id: nil)

    create(:daily_log, project: @project, task: in_phase_task, worker: @worker,
           created_by_user: @admin, hours_worked: 3, log_date: Date.current)
    create(:daily_log, project: @project, task: out_phase_task, worker: @worker,
           created_by_user: @admin, hours_worked: 4, log_date: Date.current)

    gen = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s,
      phase_ids: [ phase.id.to_s ]
    )

    result = gen.labour_by_project
    assert_equal 1, result.length
    # Only 1 worker-day for the in-phase task
    assert_equal 1, result.first[:total_days]
  end

  test "filters materials by phase_ids through tasks" do
    phase = create(:phase, project: @project)
    in_phase_task = create(:task, project: @project, phase: phase)
    out_phase_task = create(:task, project: @project, phase_id: nil)

    create(:material_entry, project: @project, task: in_phase_task, created_by_user: @admin,
           date: Date.current, description: "Insulation", quantity: 2, unit: "roll",
           unit_cost_ex_vat_ron: 50, vat_rate: 0.21)
    create(:material_entry, project: @project, task: out_phase_task, created_by_user: @admin,
           date: Date.current, description: "Glue", quantity: 1, unit: "bucket",
           unit_cost_ex_vat_ron: 80, vat_rate: 0.21)

    gen = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s,
      phase_ids: [ phase.id.to_s ]
    )

    result = gen.materials_by_project
    assert_equal 1, result.length
    assert_equal 1, result.first[:entries].length
    assert_equal "Insulation", result.first[:entries].first.description
  end

  test "returns empty data for conflicting project and task filters" do
    other_project = create(:project, :active, created_by_user: @admin)
    other_task = create(:task, project: other_project)

    gen = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s,
      project_ids: [ @project.id.to_s ],
      task_ids: [ other_task.id.to_s ]
    )

    assert_equal [], gen.labour_by_project
    assert_equal [], gen.materials_by_project
  end

  test "handles empty date range gracefully" do
    gen = ReportGenerator.new(from: "2020-01-01", to: "2020-01-31")
    assert_equal [], gen.labour_by_project
    assert_equal [], gen.materials_by_project
  end

  test "handles invalid dates gracefully" do
    gen = ReportGenerator.new(from: "not-a-date", to: "also-bad")
    assert_not_nil gen.date_range
  end
end
