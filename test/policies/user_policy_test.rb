# frozen_string_literal: true

require "test_helper"

class UserPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
    @target_user = create(:user, :owner)
  end

  test "admin can index users" do
    assert UserPolicy.new(@admin, User).index?
  end

  test "non-admin cannot index users" do
    assert_not UserPolicy.new(@owner, User).index?
    assert_not UserPolicy.new(@manager, User).index?
  end

  test "admin can create users" do
    assert UserPolicy.new(@admin, User).create?
  end

  test "non-admin cannot create users" do
    assert_not UserPolicy.new(@owner, User).create?
    assert_not UserPolicy.new(@manager, User).create?
  end

  test "admin can update users" do
    assert UserPolicy.new(@admin, @target_user).update?
  end

  test "admin can destroy other users" do
    assert UserPolicy.new(@admin, @target_user).destroy?
  end

  test "admin cannot destroy self" do
    assert_not UserPolicy.new(@admin, @admin).destroy?
  end

  test "admin can deactivate other users" do
    assert UserPolicy.new(@admin, @target_user).deactivate?
  end

  test "admin cannot deactivate self" do
    assert_not UserPolicy.new(@admin, @admin).deactivate?
  end

  test "admin can reset passwords" do
    assert UserPolicy.new(@admin, @target_user).reset_password?
  end

  test "scope returns all for admin" do
    scope = UserPolicy::Scope.new(@admin, User).resolve
    assert_includes scope, @target_user
  end

  test "scope returns none for non-admin" do
    scope = UserPolicy::Scope.new(@owner, User).resolve
    assert_empty scope
  end
end
