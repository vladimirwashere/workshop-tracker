# frozen_string_literal: true

class WorkerPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    admin_or_manager?
  end

  def update?
    admin_or_manager?
  end

  def destroy?
    admin_or_manager?
  end

  # Controls whether salary info is visible
  def view_salary?
    admin? || owner? || manager?
  end
end
