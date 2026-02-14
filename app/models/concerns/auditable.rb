# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  included do
    has_many :audit_logs, as: :auditable, dependent: :destroy

    after_create  :log_create
    after_update  :log_update
    after_discard :log_discard if respond_to?(:after_discard)
  end

  private

  def log_create
    write_audit_log("create", saved_changes.except("created_at", "updated_at"))
  end

  def log_update
    return if saved_changes.keys == %w[updated_at]

    write_audit_log("update", saved_changes.except("updated_at"))
  end

  def log_discard
    write_audit_log("discard", { discarded_at: [nil, discarded_at&.iso8601] })
  end

  def write_audit_log(action, changes_data)
    AuditLog.create!(
      auditable: self,
      action: action,
      changes_data: sanitize_audit_changes(changes_data),
      user: Current.try(:user),
      ip_address: Current.try(:session)&.ip_address
    )
  rescue StandardError => e
    Rails.logger.error("[Auditable] Failed to write audit log: #{e.message}")
  end

  def sanitize_audit_changes(changes)
    sensitive_keys = %w[password_digest password_salt confirmation_token]
    changes.except(*sensitive_keys)
  end
end
