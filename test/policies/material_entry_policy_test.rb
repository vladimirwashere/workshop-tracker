# frozen_string_literal: true

require "test_helper"

class MaterialEntryPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can index material entries" do
    assert MaterialEntryPolicy.new(@admin, MaterialEntry).index?
    assert MaterialEntryPolicy.new(@owner, MaterialEntry).index?
    assert MaterialEntryPolicy.new(@manager, MaterialEntry).index?
  end

  test "all roles can show material entries" do
    assert MaterialEntryPolicy.new(@admin, MaterialEntry).show?
    assert MaterialEntryPolicy.new(@owner, MaterialEntry).show?
    assert MaterialEntryPolicy.new(@manager, MaterialEntry).show?
  end

  test "admin and manager can create material entries, owner cannot" do
    assert MaterialEntryPolicy.new(@admin, MaterialEntry).create?
    assert_not MaterialEntryPolicy.new(@owner, MaterialEntry).create?
    assert MaterialEntryPolicy.new(@manager, MaterialEntry).create?
  end

  test "admin and manager can update material entries, owner cannot" do
    material_entry = create(:material_entry)
    assert MaterialEntryPolicy.new(@admin, material_entry).update?
    assert_not MaterialEntryPolicy.new(@owner, material_entry).update?
    assert MaterialEntryPolicy.new(@manager, material_entry).update?
  end

  test "admin and manager can destroy material entries, owner cannot" do
    material_entry = create(:material_entry)
    assert MaterialEntryPolicy.new(@admin, material_entry).destroy?
    assert_not MaterialEntryPolicy.new(@owner, material_entry).destroy?
    assert MaterialEntryPolicy.new(@manager, material_entry).destroy?
  end
end
