# frozen_string_literal: true

require "test_helper"

class WorkersControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @worker = create(:worker)
  end

  # Index

  test "all roles can list workers" do
    %i[admin owner manager].each do |role|
      user = create(:user, role)
      sign_in user
      get workers_url
      assert_response :success, "#{role} should be able to list workers"
      sign_out
    end
  end

  # Create

  test "admin can create worker" do
    sign_in @admin

    assert_difference "Worker.count", 1 do
      post workers_url, params: {
        worker: { full_name: "Ion Popescu", trade: "Electrician", active: true }
      }
    end

    assert_redirected_to worker_path(Worker.last)
  end

  test "manager can create worker" do
    sign_in @manager

    assert_difference "Worker.count", 1 do
      post workers_url, params: {
        worker: { full_name: "Maria Ionescu", trade: "Plumber", active: true }
      }
    end

    assert_redirected_to worker_path(Worker.last)
  end

  # Update

  test "admin can update worker" do
    sign_in @admin
    patch worker_url(@worker), params: { worker: { trade: "Mason" } }
    assert_redirected_to worker_path(@worker)

    @worker.reload
    assert_equal "Mason", @worker.trade
  end

  # Destroy (soft delete)

  test "manager can soft delete worker" do
    sign_in @manager
    delete worker_url(@worker)
    assert_redirected_to workers_path

    @worker.reload
    assert_not_nil @worker.discarded_at
  end
end
