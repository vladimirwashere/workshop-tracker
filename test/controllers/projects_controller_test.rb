# frozen_string_literal: true

require "test_helper"

class ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, created_by_user: @admin)
  end

  # Index

  test "all roles can list projects" do
    %i[admin owner manager].each do |role|
      user = create(:user, role)
      sign_in user
      get projects_url
      assert_response :success, "#{role} should be able to list projects"
      sign_out
    end
  end

  # Show

  test "all roles can view a project" do
    sign_in @owner
    get project_url(@project)
    assert_response :success
  end

  # Create

  test "admin can create project" do
    sign_in @admin

    assert_difference "Project.count", 1 do
      post projects_url, params: {
        project: {
          name: "New Build",
          client_name: "Acme Corp",
          status: "planned",
          planned_start_date: Date.current,
          planned_end_date: Date.current + 60.days
        }
      }
    end

    assert_redirected_to project_path(Project.last)
  end

  test "manager can create project" do
    sign_in @manager

    assert_difference "Project.count", 1 do
      post projects_url, params: {
        project: {
          name: "New Build",
          client_name: "BuildCo",
          status: "planned",
          planned_start_date: Date.current,
          planned_end_date: Date.current + 30.days
        }
      }
    end

    assert_redirected_to project_path(Project.last)
  end

  # Update

  test "admin can update project" do
    sign_in @admin
    patch project_url(@project), params: { project: { client_name: "Updated Client" } }
    assert_redirected_to project_path(@project)

    @project.reload
    assert_equal "Updated Client", @project.client_name
  end

  # Destroy (soft delete)

  test "admin can soft delete project" do
    sign_in @admin
    assert_no_difference "Project.count" do
      delete project_url(@project)
    end

    @project.reload
    assert @project.discarded?
    assert_redirected_to projects_path
  end

  test "owner cannot delete project" do
    sign_in @owner
    delete project_url(@project)
    assert_response :redirect

    @project.reload
    assert_not @project.discarded?
  end
end
