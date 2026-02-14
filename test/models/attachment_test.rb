# frozen_string_literal: true

require "test_helper"

class AttachmentTest < ActiveSupport::TestCase
  test "valid attachment" do
    attachment = build(:attachment)
    assert attachment.valid?
  end

  test "requires file_name" do
    attachment = build(:attachment, file_name: nil)
    assert_not attachment.valid?
    assert_includes attachment.errors[:file_name], "can't be blank"
  end

  test "requires uploaded_at" do
    attachment = build(:attachment, uploaded_at: nil)
    # set_uploaded_at callback should populate it
    attachment.valid?
    assert_not_nil attachment.uploaded_at
  end

  test "sets uploaded_at automatically on create" do
    attachment = create(:attachment)
    assert_not_nil attachment.uploaded_at
  end

  test "validates related_type inclusion" do
    attachment = Attachment.new(
      file_name: "test.jpg",
      uploaded_by_user: build(:user)
    )
    # Use write_attribute to bypass polymorphic constant resolution
    attachment.write_attribute(:related_type, "Session")
    attachment.write_attribute(:related_id, 1)
    assert_not attachment.valid?
    assert_includes attachment.errors[:related_type], "is not included in the list"
  end

  test "all RELATED_TYPES are valid" do
    assert_equal %w[DailyLog MaterialEntry Task], Attachment::RELATED_TYPES
  end

  test "image? returns true for image content types" do
    attachment = build(:attachment, mime_type: "image/jpeg")
    assert attachment.image?

    attachment.mime_type = "image/png"
    assert attachment.image?

    attachment.mime_type = "image/gif"
    assert attachment.image?

    attachment.mime_type = "image/webp"
    assert attachment.image?
  end

  test "image? returns false for non-image content types" do
    attachment = build(:attachment, mime_type: "application/pdf")
    assert_not attachment.image?
  end

  test "raw_image? returns true for RAW image types" do
    attachment = build(:attachment, mime_type: "image/heic")
    assert attachment.raw_image?

    attachment.mime_type = "image/x-canon-cr2"
    assert attachment.raw_image?
  end

  test "document? returns true for document content types" do
    attachment = build(:attachment, mime_type: "application/pdf")
    assert attachment.document?

    attachment.mime_type = "text/csv"
    assert attachment.document?
  end

  test "thumbnail returns variant for images" do
    attachment = create(:attachment)
    assert_not_nil attachment.thumbnail
  end

  test "thumbnail returns nil for non-images" do
    attachment = create(:attachment, :pdf)
    assert_nil attachment.thumbnail
  end

  test "soft delete with discard" do
    attachment = create(:attachment)
    attachment.discard
    assert attachment.discarded?
  end

  test "syncs metadata from blob after create" do
    attachment = create(:attachment, file_name: "test.jpg")
    attachment.reload
    assert_not_nil attachment.file_size
    assert_not_nil attachment.mime_type
  end

  test "can attach to daily_log" do
    daily_log = create(:daily_log)
    attachment = create(:attachment, related: daily_log)
    assert_equal "DailyLog", attachment.related_type
  end

  test "can attach to material_entry" do
    material_entry = create(:material_entry)
    attachment = create(:attachment, related: material_entry)
    assert_equal "MaterialEntry", attachment.related_type
  end
end
