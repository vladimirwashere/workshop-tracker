# frozen_string_literal: true

class Task < ApplicationRecord
  include Discard::Model
  include Auditable
  include DateRangeValidatable
  include Statusable
  include Attachable

  belongs_to :project
  belongs_to :phase, optional: true
  has_many :daily_logs, dependent: :restrict_with_error
  has_many :material_entries, dependent: :restrict_with_error

  validates :name, presence: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :planned_start_date, presence: true
  validates :planned_end_date, presence: true
  validate :dates_within_project_range
  validate :dates_within_phase_range, if: -> { phase_id.present? }
  validate :phase_belongs_to_project, if: -> { phase_id.present? }

  private

  def phase_belongs_to_project
    return unless phase.present? && project.present?

    errors.add(:phase_id, "must belong to the same project") unless phase.project_id == project_id
  end

  def dates_within_phase_range
    return unless phase.present? && planned_start_date.present? && planned_end_date.present?

    if planned_start_date < phase.planned_start_date
      errors.add(:planned_start_date, "cannot be before the phase start date (#{phase.planned_start_date})")
    end

    if planned_end_date > phase.planned_end_date
      errors.add(:planned_end_date, "cannot be after the phase end date (#{phase.planned_end_date})")
    end
  end
end
