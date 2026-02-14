# frozen_string_literal: true

module DateRangeValidatable
  extend ActiveSupport::Concern

  included do
    validate :end_date_after_start_date
  end

  private

  def end_date_after_start_date
    return unless planned_start_date.present? && planned_end_date.present?

    if planned_end_date < planned_start_date
      errors.add(:planned_end_date, I18n.t("activerecord.errors.messages.end_date_before_start"))
    end
  end

  def dates_within_project_range
    return unless project.present? && planned_start_date.present? && planned_end_date.present?

    if planned_start_date < project.planned_start_date
      errors.add(:planned_start_date,
        I18n.t("activerecord.errors.messages.start_date_before_project", date: project.planned_start_date))
    end

    if planned_end_date > project.planned_end_date
      errors.add(:planned_end_date,
        I18n.t("activerecord.errors.messages.end_date_after_project", date: project.planned_end_date))
    end
  end
end
