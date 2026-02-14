# frozen_string_literal: true

require "test_helper"

class WorkerSalariesControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @worker = create(:worker)
    @salary = create(:worker_salary, worker: @worker, effective_from: 6.months.ago)
  end

  # Index

  test "admin can list salary history" do
    sign_in @admin
    get worker_worker_salaries_url(@worker)
    assert_response :success
  end

  test "owner can list salary history" do
    sign_in @owner
    get worker_worker_salaries_url(@worker)
    assert_response :success
  end

  # Create

  test "admin can create salary record" do
    sign_in @admin

    assert_difference "WorkerSalary.count", 1 do
      post worker_worker_salaries_url(@worker),
           params: { worker_salary: { gross_monthly_ron: 6000, effective_from: Date.current } }
    end

    assert_redirected_to worker_worker_salaries_path(@worker)
  end

  test "manager can create salary record" do
    sign_in @manager

    assert_difference "WorkerSalary.count", 1 do
      post worker_worker_salaries_url(@worker),
           params: { worker_salary: { gross_monthly_ron: 7000, effective_from: Date.current } }
    end

    assert_redirected_to worker_worker_salaries_path(@worker)
  end

  test "owner cannot create salary record" do
    sign_in @owner

    assert_no_difference "WorkerSalary.count" do
      post worker_worker_salaries_url(@worker),
           params: { worker_salary: { gross_monthly_ron: 6000, effective_from: Date.current } }
    end
  end

  # Update

  test "admin can update salary record" do
    sign_in @admin
    patch worker_worker_salary_url(@worker, @salary),
          params: { worker_salary: { gross_monthly_ron: 8000 } }

    assert_redirected_to worker_worker_salaries_path(@worker)
    @salary.reload
    assert_equal 8000.0, @salary.gross_monthly_ron
  end

  # Destroy

  test "admin can soft delete salary record" do
    sign_in @admin

    assert_no_difference "WorkerSalary.count" do
      delete worker_worker_salary_url(@worker, @salary)
    end

    @salary.reload
    assert @salary.discarded?
    assert_redirected_to worker_worker_salaries_path(@worker)
  end

  test "owner cannot delete salary record" do
    sign_in @owner
    delete worker_worker_salary_url(@worker, @salary)

    @salary.reload
    assert_not @salary.discarded?
  end
end
