# frozen_string_literal: true

require "test_helper"

class WorkerPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
    @worker = create(:worker)
  end

  test "all roles can index workers" do
    assert WorkerPolicy.new(@admin, @worker).index?
    assert WorkerPolicy.new(@owner, @worker).index?
    assert WorkerPolicy.new(@manager, @worker).index?
  end

  test "admin and manager can create workers" do
    assert WorkerPolicy.new(@admin, @worker).create?
    assert WorkerPolicy.new(@manager, @worker).create?
  end

  test "owner cannot create workers" do
    assert_not WorkerPolicy.new(@owner, @worker).create?
  end

  test "admin and manager can update workers" do
    assert WorkerPolicy.new(@admin, @worker).update?
    assert WorkerPolicy.new(@manager, @worker).update?
  end

  test "view_salary allowed for admin, owner, manager" do
    assert WorkerPolicy.new(@admin, @worker).view_salary?
    assert WorkerPolicy.new(@owner, @worker).view_salary?
    assert WorkerPolicy.new(@manager, @worker).view_salary?
  end
end
