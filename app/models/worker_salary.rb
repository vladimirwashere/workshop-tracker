# frozen_string_literal: true

class WorkerSalary < ApplicationRecord
  include Discard::Model
  include Auditable

  belongs_to :worker

  validates :gross_monthly_ron, presence: true, numericality: { greater_than: 0 }
  validates :effective_from, presence: true,
    uniqueness: { scope: :worker_id, conditions: -> { kept } }

  before_validation :compute_derived_fields

  private

  def compute_derived_fields
    return unless gross_monthly_ron.present? && gross_monthly_ron > 0

    self.derived_daily_rate_ron = (gross_monthly_ron * 12) / 52 / 5

    cas_rate = AppConfig.get("cas_rate", "0.25").to_d
    cass_rate = AppConfig.get("cass_rate", "0.10").to_d
    income_tax_rate = AppConfig.get("income_tax_rate", "0.10").to_d

    cas = gross_monthly_ron * cas_rate
    cass = gross_monthly_ron * cass_rate
    taxable_income = gross_monthly_ron - cas - cass
    income_tax = [ taxable_income * income_tax_rate, 0 ].max

    self.net_monthly_ron = gross_monthly_ron - cas - cass - income_tax
  end
end
