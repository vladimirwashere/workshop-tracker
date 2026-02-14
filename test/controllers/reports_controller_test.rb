# frozen_string_literal: true

require "test_helper"

class ReportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, :active, created_by_user: @admin)
    @task = create(:task, project: @project)
    @worker = create(:worker)
    create(:worker_salary, worker: @worker, gross_monthly_ron: 5000, effective_from: 1.year.ago)
    create(:daily_log, project: @project, task: @task, worker: @worker,
           created_by_user: @admin, hours_worked: 8, log_date: Date.current)
    create(:material_entry, project: @project, task: @task, created_by_user: @admin,
           date: Date.current, description: "Screws", quantity: 100, unit: "pcs",
           unit_cost_ex_vat_ron: 0.5, vat_rate: 0.21)
  end

  # Access
  test "all roles can access financial reports" do
    [ @admin, @owner, @manager ].each do |user|
      sign_in user
      get financial_reports_path
      assert_response :success, "#{user.role} should access financial reports"
    end
  end

  test "all roles can access activity reports" do
    [ @admin, @owner, @manager ].each do |user|
      sign_in user
      get activity_reports_path
      assert_response :success, "#{user.role} should access activity reports"
    end
  end

  test "reports index redirects to financial" do
    sign_in @admin
    get "/reports"
    assert_response :redirect
    assert_redirected_to "/reports/financial"
  end

  # Financial – Labour reports
  test "labour summary report with date filters" do
    sign_in @admin
    get financial_reports_path(report_type: "labour", from: Date.current.beginning_of_month, to: Date.current.end_of_month)
    assert_response :success
  end

  test "labour by project when project filter present" do
    sign_in @admin
    get financial_reports_path(report_type: "labour", from: Date.current.beginning_of_month,
                     to: Date.current.end_of_month, project_ids: [ @project.id ])
    assert_response :success
  end

  # Financial – Materials report
  test "materials report shows data" do
    sign_in @admin
    get financial_reports_path(report_type: "materials", from: Date.current.beginning_of_month, to: Date.current.end_of_month)
    assert_response :success
  end

  # Financial – Combined report
  test "combined cost report shows data" do
    sign_in @admin
    get financial_reports_path(report_type: "combined", from: Date.current.beginning_of_month, to: Date.current.end_of_month)
    assert_response :success
  end

  # XLSX export
  test "labour XLSX export" do
    sign_in @admin
    get financial_reports_path(report_type: "labour", from: Date.current.beginning_of_month,
                     to: Date.current.end_of_month, format: :xlsx)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.content_type
    assert response.body.start_with?("PK")
  end

  test "combined cost XLSX export" do
    sign_in @admin
    get financial_reports_path(report_type: "combined", from: Date.current.beginning_of_month,
                     to: Date.current.end_of_month, format: :xlsx)
    assert_response :success
    assert_equal "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", response.content_type
    assert response.body.start_with?("PK")
  end

  # PDF export
  test "labour PDF export" do
    sign_in @admin
    get financial_reports_path(report_type: "labour", from: Date.current.beginning_of_month,
                     to: Date.current.end_of_month, format: :pdf)
    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert response.body.start_with?("%PDF")
  end

  # Filters
  test "financial reports filter by project" do
    sign_in @admin
    get financial_reports_path(report_type: "labour", from: Date.current.beginning_of_month,
                     to: Date.current.end_of_month, project_ids: [ @project.id ])
    assert_response :success
  end

  test "financial reports handle empty date range" do
    sign_in @admin
    get financial_reports_path(report_type: "labour", from: "2020-01-01", to: "2020-01-31")
    assert_response :success
  end

  test "combined report with project phase and task filters" do
    phase = create(:phase, project: @project)
    phased_task = create(:task, project: @project, phase: phase)
    create(:daily_log, project: @project, task: phased_task, worker: @worker,
           created_by_user: @admin, hours_worked: 4, log_date: Date.current)
    create(:material_entry, project: @project, task: phased_task, created_by_user: @admin,
           date: Date.current, description: "Sealant", quantity: 3, unit: "tube",
           unit_cost_ex_vat_ron: 10, vat_rate: 0.21)

    sign_in @admin
    get financial_reports_path(report_type: "combined", from: Date.current.beginning_of_month,
                     to: Date.current.end_of_month, project_ids: [ @project.id ],
                     phase_ids: [ phase.id ], task_ids: [ phased_task.id ])
    assert_response :success
  end

  # Activity reports
  test "activity report with filters" do
    sign_in @admin
    get activity_reports_path(from: Date.current.beginning_of_month, to: Date.current.end_of_month,
                              worker_ids: [ @worker.id ], project_ids: [ @project.id ])
    assert_response :success
  end
end
