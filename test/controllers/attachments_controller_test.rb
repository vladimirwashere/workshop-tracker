# frozen_string_literal: true

require "test_helper"

class AttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @daily_log = create(:daily_log, project: create(:project, created_by_user: @admin), created_by_user: @admin)
    @attachment = create(:attachment, related: @daily_log, uploaded_by_user: @admin)
  end

  # Index

  test "admin can list attachments for a daily_log" do
    sign_in @admin
    get attachments_url(related_type: "DailyLog", related_id: @daily_log.id)
    assert_response :success
  end

  test "index rejects invalid related_type" do
    sign_in @admin
    get attachments_url(related_type: "InvalidModel", related_id: 1)
    assert_response :redirect
  end

  # Show

  test "admin can view an attachment" do
    sign_in @admin
    get attachment_url(@attachment)
    assert_response :success
  end

  test "owner can view an attachment" do
    sign_in @owner
    get attachment_url(@attachment)
    assert_response :success
  end

  # Create

  test "admin can upload a single file" do
    sign_in @admin

    file = fixture_file_upload("test/fixtures/files/sample.txt", "text/plain")
    assert_difference "Attachment.count", 1 do
      post attachments_url, params: {
        related_type: "DailyLog",
        related_id: @daily_log.id,
        files: [ file ]
      }
    end

    assert_response :redirect
    assert_match I18n.t("attachments.created.one", count: 1), flash[:notice]
  end

  test "admin can upload multiple files" do
    sign_in @admin

    file1 = fixture_file_upload("test/fixtures/files/sample.txt", "text/plain")
    file2 = fixture_file_upload("test/fixtures/files/sample2.txt", "text/plain")

    assert_difference "Attachment.count", 2 do
      post attachments_url, params: {
        related_type: "DailyLog",
        related_id: @daily_log.id,
        files: [ file1, file2 ]
      }
    end

    assert_response :redirect
  end

  test "create with no files shows alert" do
    sign_in @admin

    assert_no_difference "Attachment.count" do
      post attachments_url, params: {
        related_type: "DailyLog",
        related_id: @daily_log.id
      }
    end

    assert_response :redirect
    assert_match I18n.t("attachments.errors.no_files_selected"), flash[:alert]
  end

  test "create rejects invalid related_type" do
    sign_in @admin

    file = fixture_file_upload("test/fixtures/files/sample.txt", "text/plain")
    assert_no_difference "Attachment.count" do
      post attachments_url, params: {
        related_type: "Session",
        related_id: 1,
        files: [ file ]
      }
    end

    assert_response :redirect
  end

  # Destroy

  test "admin can destroy an attachment" do
    sign_in @admin

    delete attachment_url(@attachment)
    assert_response :redirect
    assert_match I18n.t("attachments.deleted"), flash[:notice]

    @attachment.reload
    assert @attachment.discarded?
  end

  # Download

  test "admin can download an attachment" do
    sign_in @admin

    get download_attachment_url(@attachment)
    assert_response :redirect
  end

  test "download without file shows alert" do
    sign_in @admin

    # Create attachment without file attached
    attachment = Attachment.create!(
      file_name: "missing.txt",
      related: @daily_log,
      uploaded_by_user: @admin,
      uploaded_at: Time.current
    )

    get download_attachment_url(attachment)
    assert_response :redirect
    assert_match I18n.t("attachments.download_unavailable"), flash[:alert]
  end

  # Attaching to different models

  test "can upload to a daily_log" do
    sign_in @admin
    project = create(:project, created_by_user: @admin)
    daily_log = create(:daily_log, project: project, created_by_user: @admin)
    file = fixture_file_upload("test/fixtures/files/sample.txt", "text/plain")

    assert_difference "Attachment.count", 1 do
      post attachments_url, params: {
        related_type: "DailyLog",
        related_id: daily_log.id,
        files: [ file ]
      }
    end

    assert_equal "DailyLog", Attachment.last.related_type
  end

end
