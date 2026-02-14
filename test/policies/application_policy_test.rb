# frozen_string_literal: true

require "test_helper"

class ApplicationPolicyTest < ActiveSupport::TestCase
  test "default deny all" do
    user = create(:user, :owner)
    policy = ApplicationPolicy.new(user, nil)

    assert_not policy.index?
    assert_not policy.show?
    assert_not policy.create?
    assert_not policy.update?
    assert_not policy.destroy?
  end

  test "new? delegates to create?" do
    user = create(:user, :admin)
    policy = ApplicationPolicy.new(user, nil)
    assert_equal policy.create?, policy.new?
  end

  test "edit? delegates to update?" do
    user = create(:user, :admin)
    policy = ApplicationPolicy.new(user, nil)
    assert_equal policy.update?, policy.edit?
  end
end
