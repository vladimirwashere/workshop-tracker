# frozen_string_literal: true

class UserSettingPolicy < ApplicationPolicy
  def show?
    owns_setting?
  end

  def update?
    owns_setting?
  end

  private

  def owns_setting?
    return false unless user

    record.user_id == user.id
  end
end
