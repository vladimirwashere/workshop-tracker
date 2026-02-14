# frozen_string_literal: true

require "test_helper"

class AccountPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
  end

  test "all roles can show account" do
    assert AccountPolicy.new(@admin, :account).show?
    assert AccountPolicy.new(@owner, :account).show?
    assert AccountPolicy.new(@manager, :account).show?
  end

  test "all roles can update account" do
    assert AccountPolicy.new(@admin, :account).update?
    assert AccountPolicy.new(@owner, :account).update?
    assert AccountPolicy.new(@manager, :account).update?
  end
end
