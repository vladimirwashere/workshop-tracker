# frozen_string_literal: true

require "test_helper"

class UserSettingPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can update own setting" do
    assert UserSettingPolicy.new(@admin, @admin.user_setting).update?
    assert UserSettingPolicy.new(@manager, @manager.user_setting).update?
    assert UserSettingPolicy.new(@owner, @owner.user_setting).update?
  end

  test "no role can update another user's setting" do
    assert_not UserSettingPolicy.new(@admin, @manager.user_setting).update?
    assert_not UserSettingPolicy.new(@manager, @admin.user_setting).update?
    assert_not UserSettingPolicy.new(@owner, @admin.user_setting).update?
  end

  test "all roles can show own setting" do
    assert UserSettingPolicy.new(@admin, @admin.user_setting).show?
    assert UserSettingPolicy.new(@manager, @manager.user_setting).show?
    assert UserSettingPolicy.new(@owner, @owner.user_setting).show?
  end

  test "no role can show another user's setting" do
    assert_not UserSettingPolicy.new(@admin, @manager.user_setting).show?
    assert_not UserSettingPolicy.new(@manager, @admin.user_setting).show?
    assert_not UserSettingPolicy.new(@owner, @admin.user_setting).show?
  end
end
