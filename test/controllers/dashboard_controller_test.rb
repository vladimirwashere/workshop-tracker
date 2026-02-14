# frozen_string_literal: true

require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
  end

  test "admin can view dashboard" do
    sign_in @admin
    get dashboard_path
    assert_response :success
  end

  test "owner can view dashboard" do
    sign_in @owner
    get dashboard_path
    assert_response :success
  end

  test "manager can view dashboard" do
    sign_in @manager
    get dashboard_path
    assert_response :success
  end

  test "dashboard shows KPI data" do
    project = create(:project, :active, created_by_user: @admin)
    task = create(:task, project: project)
    worker = create(:worker)
    create(:worker_salary, worker: worker, gross_monthly_ron: 6000, effective_from: 1.year.ago)
    create(:daily_log, project: project, task: task, worker: worker,
           created_by_user: @admin, hours_worked: 8, log_date: Date.current)
    create(:material_entry, project: project, task: task, created_by_user: @admin,
           date: Date.current, description: "Wood", quantity: 10, unit: "m",
           unit_cost_ex_vat_ron: 50, vat_rate: 0.21)

    sign_in @admin
    get dashboard_path(from: Date.current.beginning_of_month, to: Date.current.end_of_month)
    assert_response :success
    assert_select "h1", t("dashboard.title")
  end

  test "dashboard accepts date range filters" do
    sign_in @admin
    get dashboard_path(from: "2025-01-01", to: "2025-12-31")
    assert_response :success
  end

  test "dashboard persists filters to user settings" do
    sign_in @admin

    setting = @admin.user_setting || @admin.create_user_setting!

    get dashboard_path(from: "2025-06-01", to: "2025-06-30")
    assert_response :success

    setting.reload
    assert_equal "2025-06-01", setting.last_dashboard_filters["from"]
    assert_equal "2025-06-30", setting.last_dashboard_filters["to"]
  end

  private

  def t(key)
    I18n.t(key)
  end
end
