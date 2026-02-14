# frozen_string_literal: true

require "test_helper"

class GanttControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, :active, created_by_user: @admin)
    @task = create(:task, project: @project, status: :in_progress)
  end

  test "admin can view gantt" do
    sign_in @admin
    get gantt_path
    assert_response :success
  end

  test "owner can view gantt" do
    sign_in @owner
    get gantt_path
    assert_response :success
  end

  test "manager can view gantt" do
    sign_in @manager
    get gantt_path
    assert_response :success
  end

  test "admin can get gantt data as JSON" do
    sign_in @admin
    get gantt_data_path, as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert data.key?("projects")
    assert_equal 1, data["projects"].length
    assert_equal @project.name, data["projects"][0]["name"]
    assert_equal 1, data["projects"][0]["tasks"].length
  end

  test "gantt data does not include hours" do
    worker = create(:worker)
    create(:daily_log, project: @project, task: @task, worker: worker,
           created_by_user: @admin, hours_worked: 6)

    sign_in @admin
    get gantt_data_path, as: :json

    task_data = JSON.parse(response.body)["projects"][0]["tasks"][0]
    assert_nil task_data["actual_hours"]
  end

  test "admin can update task dates via gantt" do
    sign_in @admin
    new_start = @project.planned_start_date + 2.days
    new_end = @project.planned_end_date - 2.days

    patch gantt_update_task_path, params: {
      task_id: @task.id,
      planned_start_date: new_start.to_s,
      planned_end_date: new_end.to_s
    }, as: :json

    assert_response :success
    result = JSON.parse(response.body)
    assert result["success"]

    @task.reload
    assert_equal new_start, @task.planned_start_date
    assert_equal new_end, @task.planned_end_date
  end

  test "manager can update task dates via gantt" do
    sign_in @manager
    new_start = @project.planned_start_date + 1.day
    new_end = @project.planned_end_date - 1.day

    patch gantt_update_task_path, params: {
      task_id: @task.id,
      planned_start_date: new_start.to_s,
      planned_end_date: new_end.to_s
    }, as: :json

    assert_response :success
    result = JSON.parse(response.body)
    assert result["success"]
  end

  test "gantt update rejects dates outside project range" do
    sign_in @admin
    patch gantt_update_task_path, params: {
      task_id: @task.id,
      planned_start_date: (@project.planned_start_date - 10.days).to_s,
      planned_end_date: (@project.planned_end_date + 10.days).to_s
    }, as: :json

    assert_response :unprocessable_entity
    result = JSON.parse(response.body)
    assert_not result["success"]
    assert result["error"].present?
  end

  test "gantt update handles invalid date format" do
    sign_in @admin
    patch gantt_update_task_path, params: {
      task_id: @task.id,
      planned_start_date: "not-a-date",
      planned_end_date: "also-not"
    }, as: :json

    assert_response :unprocessable_entity
    result = JSON.parse(response.body)
    assert_not result["success"]
  end
end
