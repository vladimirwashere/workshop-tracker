# frozen_string_literal: true

require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, created_by_user: @admin)
  end

  # Create

  test "admin can create task under project" do
    sign_in @admin

    assert_difference "Task.count", 1 do
      post project_tasks_url(@project), params: {
        task: {
          name: "Foundation Work",
          status: "planned",
          priority: "high",
          planned_start_date: @project.planned_start_date,
          planned_end_date: @project.planned_start_date + 10.days
        }
      }
    end

    task = Task.last
    assert_redirected_to project_path(@project)
    assert_equal @project.id, task.project_id
  end

  test "manager can create task under project" do
    sign_in @manager

    assert_difference "Task.count", 1 do
      post project_tasks_url(@project), params: {
        task: {
          name: "Plumbing",
          status: "planned",
          priority: "medium",
          planned_start_date: @project.planned_start_date,
          planned_end_date: @project.planned_start_date + 5.days
        }
      }
    end

    assert_redirected_to project_path(@project)
  end

  # for_project JSON endpoint

  test "for_project returns JSON list of tasks with phase_id" do
    task = create(:task, project: @project, name: "Plumbing", phase_id: nil)
    sign_in @admin

    get tasks_for_project_url(@project)
    assert_response :success

    body = JSON.parse(response.body)
    assert_kind_of Array, body
    assert_equal 1, body.size
    assert_equal "Plumbing", body.first["name"]
    assert_equal task.id, body.first["id"]
    assert_equal @project.id, body.first["project_id"]
    assert_nil body.first["phase_id"]
  end

  test "for_project filters by phase_id when given" do
    phase = create(:phase, project: @project)
    task_in_phase = create(:task, project: @project, phase: phase, name: "In Phase")
    task_no_phase = create(:task, project: @project, phase_id: nil, name: "No Phase")
    sign_in @admin

    get tasks_for_project_url(@project), params: { phase_id: phase.id }
    assert_response :success

    body = JSON.parse(response.body)
    assert_equal 1, body.size
    assert_equal "In Phase", body.first["name"]
    assert_equal task_in_phase.id, body.first["id"]
    assert_equal phase.id, body.first["phase_id"]
  end

  test "can create task with phase_id" do
    phase = create(:phase, project: @project)
    sign_in @admin

    assert_difference "Task.count", 1 do
      post project_tasks_url(@project), params: {
        task: {
          name: "Phase Task",
          status: "planned",
          priority: "medium",
          phase_id: phase.id,
          planned_start_date: phase.planned_start_date,
          planned_end_date: phase.planned_end_date
        }
      }
    end

    task = Task.last
    assert_equal phase.id, task.phase_id
  end
end
