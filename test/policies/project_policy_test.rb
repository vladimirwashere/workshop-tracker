# frozen_string_literal: true

require "test_helper"

class ProjectPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
    @project = create(:project)
  end

  test "all roles can index projects" do
    assert ProjectPolicy.new(@admin, @project).index?
    assert ProjectPolicy.new(@owner, @project).index?
    assert ProjectPolicy.new(@manager, @project).index?
  end

  test "all roles can show projects" do
    assert ProjectPolicy.new(@admin, @project).show?
    assert ProjectPolicy.new(@owner, @project).show?
    assert ProjectPolicy.new(@manager, @project).show?
  end

  test "admin and manager can create projects, owner cannot" do
    assert ProjectPolicy.new(@admin, @project).create?
    assert_not ProjectPolicy.new(@owner, @project).create?
    assert ProjectPolicy.new(@manager, @project).create?
  end

  test "admin and manager can update projects, owner cannot" do
    assert ProjectPolicy.new(@admin, @project).update?
    assert_not ProjectPolicy.new(@owner, @project).update?
    assert ProjectPolicy.new(@manager, @project).update?
  end

  test "admin and manager can destroy projects, owner cannot" do
    assert ProjectPolicy.new(@admin, @project).destroy?
    assert_not ProjectPolicy.new(@owner, @project).destroy?
    assert ProjectPolicy.new(@manager, @project).destroy?
  end

  test "scope returns kept projects" do
    discarded = create(:project, :discarded)
    scope = ProjectPolicy::Scope.new(@admin, Project).resolve
    assert_includes scope, @project
    assert_not_includes scope, discarded
  end
end
