# frozen_string_literal: true

class Worker < ApplicationRecord
  include Discard::Model
  include Auditable

  has_many :worker_salaries, dependent: :restrict_with_error
  has_many :daily_logs, dependent: :restrict_with_error

  validates :full_name, presence: true, length: { maximum: 150 }
  validates :trade, length: { maximum: 100 }
  validates :notes, length: { maximum: 5000 }

  scope :active_workers, -> { kept.where(active: true) }

  def current_salary(date = Date.current)
    worker_salaries
      .kept
      .where("effective_from <= ?", date)
      .order(effective_from: :desc)
      .first
  end

  # Uses the already-loaded association to avoid N+1 queries.
  # Call this when worker_salaries has been eager-loaded.
  def current_salary_cached(date = Date.current)
    worker_salaries
      .select(&:kept?)
      .select { |s| s.effective_from <= date }
      .max_by(&:effective_from)
  end

  def daily_rate_cached(date = Date.current)
    current_salary_cached(date)&.derived_daily_rate_ron
  end
end
