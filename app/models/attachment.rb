# frozen_string_literal: true

class Attachment < ApplicationRecord
  include Discard::Model
  include Auditable

  MAX_FILE_SIZE = 25.megabytes

  RELATED_TYPES = %w[DailyLog MaterialEntry Task].freeze

  IMAGE_CONTENT_TYPES = %w[
    image/jpeg
    image/png
    image/gif
    image/webp
  ].freeze

  RAW_IMAGE_CONTENT_TYPES = %w[
    image/heic
    image/heif
    image/tiff
    image/x-canon-cr2
    image/x-nikon-nef
    image/x-sony-arw
    image/x-adobe-dng
    image/x-panasonic-rw2
    image/x-olympus-orf
    image/x-fuji-raf
  ].freeze

  DOCUMENT_CONTENT_TYPES = %w[
    application/pdf
    application/msword
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
    application/vnd.ms-excel
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
    text/csv
    text/plain
    text/markdown
  ].freeze

  CAD_CONTENT_TYPES = %w[
    application/acad
    application/x-dwg
    image/vnd.dwg
  ].freeze

  ALLOWED_CONTENT_TYPES = (
    IMAGE_CONTENT_TYPES +
    RAW_IMAGE_CONTENT_TYPES +
    DOCUMENT_CONTENT_TYPES +
    CAD_CONTENT_TYPES
  ).freeze

  belongs_to :related, polymorphic: true
  belongs_to :uploaded_by_user, class_name: "User"

  has_one_attached :file

  validates :related_type, inclusion: { in: RELATED_TYPES }
  validates :file_name, presence: true
  validates :uploaded_at, presence: true
  validate :acceptable_file, if: -> { file.attached? }

  before_validation :set_uploaded_at, on: :create
  after_commit :sync_metadata_from_blob, on: :create

  def image?
    IMAGE_CONTENT_TYPES.include?(mime_type)
  end

  def raw_image?
    RAW_IMAGE_CONTENT_TYPES.include?(mime_type)
  end

  def document?
    DOCUMENT_CONTENT_TYPES.include?(mime_type)
  end

  def thumbnail
    return unless image? && file.attached?

    file.variant(resize_to_limit: [ 300, 300 ])
  end

  private

  def set_uploaded_at
    self.uploaded_at ||= Time.current
  end

  def sync_metadata_from_blob
    return unless file.attached?

    blob = file.blob
    update_columns(
      file_name: file_name.presence || blob.filename.to_s,
      file_size: blob.byte_size,
      mime_type: blob.content_type
    )
  end

  def acceptable_file
    blob = file.blob

    unless blob.byte_size <= MAX_FILE_SIZE
      errors.add(:file, I18n.t("attachments.errors.file_too_large", max_size: "25 MB"))
      return
    end

    detected_type = begin
      blob.open do |tempfile|
        Marcel::MimeType.for(tempfile, name: blob.filename.to_s)
      end
    rescue ActiveStorage::FileNotFoundError
      blob.content_type
    end

    unless ALLOWED_CONTENT_TYPES.include?(detected_type)
      errors.add(:file, I18n.t("attachments.errors.invalid_content_type"))
    end
  end
end
