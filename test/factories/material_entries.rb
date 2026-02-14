# frozen_string_literal: true

FactoryBot.define do
  factory :material_entry do
    project
    date { Date.current }
    description { "Timber planks" }
    quantity { 10 }
    unit { "pcs" }
    unit_cost_ex_vat_ron { 50.00 }
    unit_cost_inc_vat_ron { 60.50 }
    vat_rate { 0.21 }
    association :created_by_user, factory: :user
    # total and inc-vat fields are computed by callback
  end
end
