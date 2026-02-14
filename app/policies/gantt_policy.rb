# frozen_string_literal: true

class GanttPolicy < ApplicationPolicy
  def show?
    admin_or_owner_or_manager?
  end

  def update?
    admin_or_manager?
  end
end
