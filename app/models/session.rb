# frozen_string_literal: true

class Session < ApplicationRecord
  SESSION_LIFETIME = 30.days

  belongs_to :user

  before_create :set_expires_at

  scope :expired, -> { where("expires_at <= ?", Time.current) }

  def expired?
    expires_at.present? && expires_at <= Time.current
  end

  private

  def set_expires_at
    self.expires_at ||= SESSION_LIFETIME.from_now
  end
end
