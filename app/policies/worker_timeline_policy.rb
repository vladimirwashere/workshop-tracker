# frozen_string_literal: true

class WorkerTimelinePolicy < ApplicationPolicy
  def index?
    admin_or_owner_or_manager?
  end

  def show?
    admin_or_owner_or_manager?
  end
end
