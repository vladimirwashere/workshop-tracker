# frozen_string_literal: true

module Statusable
  extend ActiveSupport::Concern

  included do
    enum :status, { planned: 0, in_progress: 1, done: 2, cancelled: 3 }
    enum :priority, { low: 0, medium: 1, high: 2 }
  end
end
