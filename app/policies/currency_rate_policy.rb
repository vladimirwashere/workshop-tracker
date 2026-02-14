# frozen_string_literal: true

class CurrencyRatePolicy < ApplicationPolicy
  def index?
    admin_or_owner_or_manager?
  end

  def fetch_latest?
    admin_or_manager?
  end
end
