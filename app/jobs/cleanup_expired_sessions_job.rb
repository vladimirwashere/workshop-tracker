# frozen_string_literal: true

class CleanupExpiredSessionsJob < ApplicationJob
  queue_as :default

  def perform
    count = Session.expired.delete_all
    Rails.logger.info("[CleanupExpiredSessionsJob] Removed #{count} expired sessions")
  end
end
