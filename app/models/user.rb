# frozen_string_literal: true

class User < ApplicationRecord
  include Discard::Model
  include Auditable

  has_secure_password
  encrypts :email_address, deterministic: true, downcase: true
  has_many :sessions, dependent: :destroy
  has_many :password_histories, dependent: :destroy
  has_one :user_setting, dependent: :destroy
  has_many :created_projects, class_name: "Project", foreign_key: :created_by_user_id,
    inverse_of: :created_by_user, dependent: :restrict_with_error
  has_many :created_daily_logs, class_name: "DailyLog", foreign_key: :created_by_user_id,
    inverse_of: :created_by_user, dependent: :restrict_with_error
  has_many :created_material_entries, class_name: "MaterialEntry", foreign_key: :created_by_user_id,
    inverse_of: :created_by_user, dependent: :restrict_with_error
  has_many :uploaded_attachments, class_name: "Attachment", foreign_key: :uploaded_by_user_id,
    inverse_of: :uploaded_by_user, dependent: :restrict_with_error
  has_many :audit_logs, dependent: :nullify

  generates_token_for :password_reset, expires_in: 15.minutes do
    password_salt&.last(10)
  end

  enum :role, { admin: 0, owner: 1, manager: 2 }

  normalizes :email_address, with: ->(e) { e.strip }

  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, if: -> { password.present? }
  validate :password_complexity, if: -> { password.present? }
  validate :password_not_reused, if: -> { password.present? && persisted? && password_digest_changed? }
  validates :role, presence: true
  validates :display_name, presence: true, length: { maximum: 100 }
  validates :email_address, length: { maximum: 255 }

  after_create :create_default_settings
  after_save :archive_password, if: :saved_change_to_password_digest?

  def confirmed?
    confirmed_at.present?
  end

  def generate_confirmation_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(confirmation_token: Digest::SHA256.hexdigest(raw_token))
    raw_token
  end

  def self.find_by_confirmation_token(raw_token)
    find_by(confirmation_token: Digest::SHA256.hexdigest(raw_token))
  end

  private

  def password_complexity
    return if password.blank?

    unless password.match?(/[A-Z]/) && password.match?(/[a-z]/) && password.match?(/\d/)
      errors.add(:password, I18n.t("activerecord.errors.messages.password_complexity"))
    end
  end

  def create_default_settings
    build_user_setting(last_gantt_zoom: 7).save!
  end

  def password_not_reused
    if PasswordHistory.previously_used?(self, password)
      errors.add(:password, I18n.t("activerecord.errors.messages.password_reused"))
    end
  end

  def archive_password
    password_histories.create!(password_digest: password_digest)
  end
end
