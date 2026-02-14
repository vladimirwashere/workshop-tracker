# frozen_string_literal: true

class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    # Default: return kept records for Discard models, all otherwise
    def resolve
      scope.respond_to?(:kept) ? scope.kept : scope.all
    end

    private

    attr_reader :user, :scope

    def admin?
      user.admin?
    end

    def owner?
      user.owner?
    end

    def manager?
      user.manager?
    end
  end

  private

  def admin?
    user.admin?
  end

  def owner?
    user.owner?
  end

  def manager?
    user.manager?
  end

  def admin_or_owner_or_manager?
    admin? || owner? || manager?
  end

  def admin_or_manager?
    admin? || manager?
  end

  def can_view_reports?
    admin_or_owner_or_manager?
  end

  def can_view_costs?
    admin_or_owner_or_manager?
  end
end
