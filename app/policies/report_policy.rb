# frozen_string_literal: true

class ReportPolicy < ApplicationPolicy
  def financial?
    can_view_reports?
  end

  def activity?
    can_view_reports?
  end
end
