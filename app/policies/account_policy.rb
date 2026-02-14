# frozen_string_literal: true

class AccountPolicy < ApplicationPolicy
  def show?
    true
  end

  def update?
    true
  end
end
