# frozen_string_literal: true

class AttachmentsController < ApplicationController
  rate_limit to: 20, within: 1.minute, only: :create, with: -> { redirect_back fallback_location: root_path, alert: t("sessions.rate_limited") }

  before_action :set_attachment, only: %i[show destroy download]
  before_action :set_related, only: %i[index create]

  def index
    authorize Attachment
    @attachments = policy_scope(@related.attachments).includes(:uploaded_by_user, file_attachment: :blob).order(created_at: :desc)
  end

  def show
    authorize @attachment
  end

  def create
    authorize Attachment

    files = Array(params[:files])
    if files.empty?
      redirect_back fallback_location: polymorphic_show_path(@related),
                    alert: t("attachments.errors.no_files_selected")
      return
    end

    created = []
    errors = []

    files.each do |uploaded_file|
      attachment = @related.attachments.build(
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

    if errors.any?
      flash[:alert] = t("attachments.errors.some_failed", errors: errors.join("; "))
    end

    if created.any?
      flash[:notice] = t("attachments.created", count: created.size)
    end

    redirect_back fallback_location: polymorphic_show_path(@related)
  end

  def destroy
    authorize @attachment
    @attachment.discard

    redirect_back fallback_location: root_path, notice: t("attachments.deleted")
  end

  def download
    authorize @attachment

    if @attachment.file.attached?
      redirect_to rails_blob_path(@attachment.file, disposition: "attachment"), allow_other_host: true
    else
      redirect_back fallback_location: attachment_path(@attachment), alert: t("attachments.download_unavailable")
    end
  end

  private

  def set_attachment
    @attachment = Attachment.kept.find(params[:id])
  end

  RELATED_MODELS = Attachment::RELATED_TYPES.index_with { |t| t.constantize }.freeze

  def set_related
    related_type = params[:related_type]
    related_id = params[:related_id]

    model = RELATED_MODELS[related_type]
    unless model
      redirect_back fallback_location: root_path, alert: t("common.not_authorized")
      return
    end

    @related = model.kept.find(related_id)
    authorize @related, :show?
  end

  def polymorphic_show_path(record)
    case record
    when Task
      project_task_path(record.project, record)
    when MaterialEntry
      record.project ? project_material_entry_path(record.project, record) : material_entry_path(record)
    else
      polymorphic_path(record)
    end
  end
end
