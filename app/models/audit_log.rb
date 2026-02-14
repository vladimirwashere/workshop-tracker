# frozen_string_literal: true

class AuditLog < ApplicationRecord
  belongs_to :auditable, polymorphic: true
  belongs_to :user, optional: true

  ACTIONS = %w[create update destroy discard failed_login].freeze

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :auditable_type, presence: true
end
