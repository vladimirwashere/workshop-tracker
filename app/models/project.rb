# frozen_string_literal: true

class Project < ApplicationRecord
  include Discard::Model
  include DateRangeValidatable
  include Auditable
  include CreatedByUser

  has_many :phases, dependent: :restrict_with_error
  has_many :tasks, dependent: :restrict_with_error
  has_many :daily_logs, dependent: :restrict_with_error
  has_many :material_entries, dependent: :restrict_with_error

  enum :status, { planned: 0, active: 1, completed: 2, on_hold: 3, cancelled: 4 }

  validates :name, presence: true, length: { maximum: 255 }
  validates :client_name, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :planned_start_date, presence: true
  validates :planned_end_date, presence: true
  validate :completion_requires_all_tasks_finished, if: -> { completed? }

  scope :active_projects, -> { kept.where.not(status: :cancelled) }

  private

  def completion_requires_all_tasks_finished
    unfinished = tasks.kept.where.not(status: %i[done cancelled])
    if unfinished.exists?
      errors.add(:status, "cannot be completed while tasks are still open")
    end
  end
end
