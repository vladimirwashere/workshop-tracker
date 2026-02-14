# frozen_string_literal: true

class UserSetting < ApplicationRecord
  belongs_to :user

  enum :default_currency_display, { RON: 0, GBP: 1 }, prefix: :currency

  GANTT_ZOOM_OPTIONS = [7, 14, 30, 90, 180, 365].freeze

  validates :last_gantt_zoom, inclusion: { in: GANTT_ZOOM_OPTIONS }
end
