# frozen_string_literal: true

class WorkerSalaryPolicy < ApplicationPolicy
  def index?
    can_view_costs?
  end

  def show?
    can_view_costs?
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

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.manager? || user.owner?
        scope.kept
      else
        scope.none
      end
    end
  end
end
