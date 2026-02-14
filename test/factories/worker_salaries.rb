# frozen_string_literal: true

FactoryBot.define do
  factory :worker_salary do
    worker
    gross_monthly_ron { 5000.00 }
    effective_from { Date.current }
    # derived_daily_rate_ron and net_monthly_ron are computed by callback
  end
end
