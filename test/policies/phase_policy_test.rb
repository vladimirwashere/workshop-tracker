# frozen_string_literal: true

require "test_helper"

class PhasePolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
    @phase = create(:phase)
  end

  test "all roles can index phases" do
    assert PhasePolicy.new(@admin, @phase).index?
    assert PhasePolicy.new(@owner, @phase).index?
    assert PhasePolicy.new(@manager, @phase).index?
  end

  test "all roles can show phases" do
    assert PhasePolicy.new(@admin, @phase).show?
    assert PhasePolicy.new(@owner, @phase).show?
    assert PhasePolicy.new(@manager, @phase).show?
  end

  test "admin and manager can create phases, owner cannot" do
    assert PhasePolicy.new(@admin, @phase).create?
    assert_not PhasePolicy.new(@owner, @phase).create?
    assert PhasePolicy.new(@manager, @phase).create?
  end

  test "admin and manager can update phases, owner cannot" do
    assert PhasePolicy.new(@admin, @phase).update?
    assert_not PhasePolicy.new(@owner, @phase).update?
    assert PhasePolicy.new(@manager, @phase).update?
  end

  test "admin and manager can destroy phases, owner cannot" do
    assert PhasePolicy.new(@admin, @phase).destroy?
    assert_not PhasePolicy.new(@owner, @phase).destroy?
    assert PhasePolicy.new(@manager, @phase).destroy?
  end
end
