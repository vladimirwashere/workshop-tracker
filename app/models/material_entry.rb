# frozen_string_literal: true

class MaterialEntry < ApplicationRecord
  include Discard::Model
  include Attachable
  include Auditable
  include CreatedByUser

  belongs_to :project
  belongs_to :task, optional: true

  validates :date, presence: true
  validates :description, presence: true, length: { maximum: 500 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true, length: { maximum: 50 }
  validates :supplier_name, length: { maximum: 255 }
  validates :unit_cost_ex_vat_ron, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :unit_cost_inc_vat_ron, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validate :at_least_one_unit_cost

  VAT_RATES = [0, 0.21].map { |r| BigDecimal(r.to_s) }.freeze
  DEFAULT_VAT_RATE = VAT_RATES.last # 0.21

  validates :vat_rate, presence: true, inclusion: { in: VAT_RATES }

  # Virtual attribute: "inc" or "ex" — controls which cost drives the calculation
  attr_accessor :vat_input_mode

  before_validation :derive_unit_costs
  before_validation :compute_totals

  private

  def at_least_one_unit_cost
    if unit_cost_ex_vat_ron.blank? && unit_cost_inc_vat_ron.blank?
      errors.add(:unit_cost_ex_vat_ron, :blank)
    end
  end

  def derive_unit_costs
    return unless vat_rate.present?

    multiplier = 1 + vat_rate

    if vat_input_mode == "inc"
      if unit_cost_inc_vat_ron.present?
        self.unit_cost_ex_vat_ron = (unit_cost_inc_vat_ron / multiplier).round(2)
      end
    else
      if unit_cost_ex_vat_ron.present?
        self.unit_cost_inc_vat_ron = (unit_cost_ex_vat_ron * multiplier).round(2)
      end
    end
  end

  def compute_totals
    return unless quantity.present? && unit_cost_ex_vat_ron.present? && vat_rate.present?

    self.total_cost_ex_vat_ron = quantity * unit_cost_ex_vat_ron
    self.total_vat_ron = total_cost_ex_vat_ron * vat_rate
    self.total_cost_inc_vat_ron = total_cost_ex_vat_ron + total_vat_ron
  end
end
