# frozen_string_literal: true

require "test_helper"

class ConfigPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can index configs" do
    assert ConfigPolicy.new(@admin, Config).index?
    assert ConfigPolicy.new(@manager, Config).index?
    assert ConfigPolicy.new(@owner, Config).index?
  end

  test "admin and manager can update configs, owner cannot" do
    assert ConfigPolicy.new(@admin, Config).update?
    assert ConfigPolicy.new(@manager, Config).update?
    assert_not ConfigPolicy.new(@owner, Config).update?
  end

  test "all roles can show configs" do
    config = create(:config)
    assert ConfigPolicy.new(@admin, config).show?
    assert ConfigPolicy.new(@manager, config).show?
    assert ConfigPolicy.new(@owner, config).show?
  end
end
