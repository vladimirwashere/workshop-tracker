# frozen_string_literal: true

require "test_helper"

class PhasesControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, created_by_user: @admin)
  end

  test "new renders form" do
    sign_in @admin
    get new_project_phase_url(@project)
    assert_response :success
  end

  test "admin can create phase" do
    sign_in @admin

    assert_difference "Phase.count", 1 do
      post project_phases_url(@project), params: {
        phase: {
          name: "Foundation Phase",
          status: "planned",
          priority: "high",
          planned_start_date: @project.planned_start_date,
          planned_end_date: @project.planned_start_date + 14.days
        }
      }
    end

    phase = Phase.last
    assert_redirected_to project_path(@project)
    assert_equal @project.id, phase.project_id
  end

  test "manager can create phase" do
    sign_in @manager

    assert_difference "Phase.count", 1 do
      post project_phases_url(@project), params: {
        phase: {
          name: "Finishing Phase",
          status: "planned",
          priority: "medium",
          planned_start_date: @project.planned_start_date,
          planned_end_date: @project.planned_start_date + 5.days
        }
      }
    end

    assert_redirected_to project_path(@project)
  end

  test "admin can update phase" do
    phase = create(:phase, project: @project, name: "Original")
    sign_in @admin

    patch project_phase_url(@project, phase), params: { phase: { name: "Updated Name" } }
    assert_redirected_to project_path(@project)

    phase.reload
    assert_equal "Updated Name", phase.name
  end

  test "admin can destroy phase" do
    phase = create(:phase, project: @project)
    sign_in @admin

    delete project_phase_url(@project, phase)
    assert_redirected_to project_path(@project)

    phase.reload
    assert phase.discarded?
  end

  test "show renders phase details" do
    phase = create(:phase, project: @project)
    sign_in @admin
    get project_phase_url(@project, phase)
    assert_response :success
  end

  # for_project JSON endpoint

  test "for_project returns JSON list of phases" do
    phase = create(:phase, project: @project, name: "Foundation")
    sign_in @admin

    get phases_for_project_url(@project)
    assert_response :success

    body = JSON.parse(response.body)
    assert_kind_of Array, body
    assert_equal 1, body.size
    assert_equal "Foundation", body.first["name"]
    assert_equal phase.id, body.first["id"]
  end
end
