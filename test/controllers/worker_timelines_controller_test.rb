# frozen_string_literal: true

require "test_helper"

class WorkerTimelinesControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @worker = create(:worker, active: true)
    @project = create(:project, :active, created_by_user: @admin)
    @task = create(:task, project: @project)
  end

  test "admin can view timelines index" do
    sign_in @admin
    get worker_timelines_path
    assert_response :success
  end

  test "owner can view timelines index" do
    sign_in @owner
    get worker_timelines_path
    assert_response :success
  end

  test "manager can view timelines index" do
    sign_in @manager
    get worker_timelines_path
    assert_response :success
  end

  test "admin can view worker timeline" do
    sign_in @admin
    get worker_timeline_path(worker_id: @worker.id)
    assert_response :success
  end

  test "admin can get worker timeline JSON" do
    create(:daily_log, project: @project, task: @task, worker: @worker,
           created_by_user: @admin, hours_worked: 7.5)

    sign_in @admin
    get worker_timeline_path(worker_id: @worker.id), as: :json
    assert_response :success

    data = JSON.parse(response.body)
    assert_equal @worker.full_name, data["worker"]
    assert_equal 1, data["logs"].length
    assert_equal 7.5, data["logs"][0]["hours"]
  end

  test "admin timeline JSON includes costs" do
    create(:worker_salary, worker: @worker, gross_monthly_ron: 5000, effective_from: 1.year.ago)
    create(:daily_log, project: @project, task: @task, worker: @worker,
           created_by_user: @admin, hours_worked: 8)

    sign_in @admin
    get worker_timeline_path(worker_id: @worker.id), as: :json

    data = JSON.parse(response.body)
    assert_not_nil data["logs"][0]["cost"]
  end
end
