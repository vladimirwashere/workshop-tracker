# frozen_string_literal: true

require "test_helper"

class DailyLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, :active, created_by_user: @admin)
    @task = create(:task, project: @project)
    @worker = create(:worker)
    create(:worker_salary, worker: @worker, effective_from: Date.current - 30.days)
  end

  # Index

  test "all roles can list daily logs" do
    %i[admin owner manager].each do |role|
      user = create(:user, role)
      sign_in user
      get daily_logs_url
      assert_response :success, "#{role} should be able to list daily logs"
      sign_out
    end
  end

  # Create

  test "admin can create daily log" do
    sign_in @admin

    assert_difference "DailyLog.count", 1 do
      post daily_logs_url, params: {
        daily_log: {
          project_id: @project.id,
          task_id: @task.id,
          worker_id: @worker.id,
          log_date: Date.current,
          hours_worked: 8,
          scope: "Completed foundation work"
        }
      }
    end

    assert_redirected_to daily_logs_path(from: Date.current, to: Date.current)
  end

  test "manager can create daily log" do
    sign_in @manager

    assert_difference "DailyLog.count", 1 do
      post daily_logs_url, params: {
        daily_log: {
          project_id: @project.id,
          task_id: @task.id,
          worker_id: @worker.id,
          log_date: Date.current,
          hours_worked: 8,
          scope: "Full day"
        }
      }
    end

    assert_redirected_to daily_logs_path(from: Date.current, to: Date.current)
  end

  # Edit

  test "admin can access edit page for daily log" do
    daily_log = create(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @admin)
    sign_in @admin

    get edit_daily_log_url(daily_log)
    assert_response :success
  end

  # Session defaults

  test "new with session defaults pre-fills project, task, worker" do
    sign_in @admin
    post daily_logs_url, params: {
      daily_log: {
        project_id: @project.id,
        task_id: @task.id,
        worker_id: @worker.id,
        log_date: Date.current,
        hours_worked: 8,
        scope: "First log"
      }
    }
    assert_redirected_to daily_logs_path(from: Date.current, to: Date.current)

    get new_daily_log_url
    assert_response :success
    assert_select "select#daily_log_project_id" do
      assert_select "option[selected=selected][value='#{@project.id}']", 1
    end
    assert_select "select#daily_log_task_id" do
      assert_select "option[selected=selected][value='#{@task.id}']", 1
    end
    assert_select "select#daily_log_worker_id" do
      assert_select "option[selected=selected][value='#{@worker.id}']", 1
    end
  end

  test "create persists session defaults for next new" do
    sign_in @admin
    post daily_logs_url, params: {
      daily_log: {
        project_id: @project.id,
        task_id: @task.id,
        worker_id: @worker.id,
        log_date: Date.current,
        hours_worked: 8
      }
    }
    assert_redirected_to daily_logs_path(from: Date.current, to: Date.current)
    get new_daily_log_url
    assert_response :success
    assert_select "select#daily_log_project_id" do
      assert_select "option[selected=selected][value='#{@project.id}']", 1
    end
  end

  test "update persists session defaults for next new" do
    daily_log = create(:daily_log, project: @project, task: @task, worker: @worker, created_by_user: @admin)
    sign_in @admin

    patch daily_log_url(daily_log), params: {
      daily_log: {
        project_id: @project.id,
        task_id: @task.id,
        worker_id: @worker.id,
        log_date: daily_log.log_date,
        hours_worked: 7,
        scope: "Updated"
      }
    }
    assert_redirected_to daily_logs_path(from: daily_log.log_date, to: daily_log.log_date)

    get new_daily_log_url
    assert_response :success
    assert_select "select#daily_log_project_id" do
      assert_select "option[selected=selected][value='#{@project.id}']", 1
    end
  end
end
