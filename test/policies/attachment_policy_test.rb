# frozen_string_literal: true

require "test_helper"

class AttachmentPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @owner = create(:user, :owner)
    @manager = create(:user, :manager)
    @attachment = create(:attachment)
  end

  test "all roles can index attachments" do
    assert AttachmentPolicy.new(@admin, Attachment).index?
    assert AttachmentPolicy.new(@owner, Attachment).index?
    assert AttachmentPolicy.new(@manager, Attachment).index?
  end

  test "all roles can show attachments" do
    assert AttachmentPolicy.new(@admin, @attachment).show?
    assert AttachmentPolicy.new(@owner, @attachment).show?
    assert AttachmentPolicy.new(@manager, @attachment).show?
  end

  test "admin and manager can create attachments, owner cannot" do
    assert AttachmentPolicy.new(@admin, Attachment).create?
    assert_not AttachmentPolicy.new(@owner, Attachment).create?
    assert AttachmentPolicy.new(@manager, Attachment).create?
  end

  test "admin and manager can destroy attachments, owner cannot" do
    assert AttachmentPolicy.new(@admin, @attachment).destroy?
    assert_not AttachmentPolicy.new(@owner, @attachment).destroy?
    assert AttachmentPolicy.new(@manager, @attachment).destroy?
  end

  test "all roles can download attachments" do
    assert AttachmentPolicy.new(@admin, @attachment).download?
    assert AttachmentPolicy.new(@owner, @attachment).download?
    assert AttachmentPolicy.new(@manager, @attachment).download?
  end
end
