# frozen_string_literal: true

module CreatesAttachmentsFromParams
  extend ActiveSupport::Concern

  # Returns [created_count, errors_array]
  def create_attachments_for(related)
    files = Array(params[:files])
    return [0, []] if files.empty?
    return [0, []] unless policy(Attachment).create?

    created = []
    errors = []

    files.each do |uploaded_file|
      attachment = related.attachments.build(
        file_name: uploaded_file.original_filename,
        uploaded_by_user: Current.user
      )
      attachment.file.attach(uploaded_file)

      if attachment.save
        created << attachment
      else
        errors << "#{uploaded_file.original_filename}: #{attachment.errors.full_messages.join(', ')}"
      end
    end

    [created.size, errors]
  end

  # Builds the combined notice and sets flash[:alert] for attachment errors
  def notice_with_attachments(base_notice, related)
    created_count, attachment_errors = create_attachments_for(related)
    notice = base_notice
    notice += " #{t('attachments.created', count: created_count)}" if created_count.positive?
    flash[:alert] = t("attachments.errors.some_failed", errors: attachment_errors.join("; ")) if attachment_errors.any?
    notice
  end
end
