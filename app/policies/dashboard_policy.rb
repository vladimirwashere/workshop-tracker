# frozen_string_literal: true

class DashboardPolicy < ApplicationPolicy
  def show?
    can_view_reports?
  end
end
