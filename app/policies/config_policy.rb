# frozen_string_literal: true

class ConfigPolicy < ApplicationPolicy
  def index?
    admin_or_owner_or_manager?
  end

  def show?
    admin_or_owner_or_manager?
  end

  def update?
    admin_or_manager?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin? || owner? || manager?
        scope.all
      else
        scope.none
      end
    end
  end
end
