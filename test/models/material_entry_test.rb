# frozen_string_literal: true

require "test_helper"

class MaterialEntryTest < ActiveSupport::TestCase
  test "valid material entry" do
    entry = build(:material_entry)
    assert entry.valid?
  end

  test "requires description" do
    entry = build(:material_entry, description: nil)
    assert_not entry.valid?
  end

  test "requires quantity" do
    entry = build(:material_entry, quantity: nil)
    assert_not entry.valid?
  end

  test "quantity must be positive" do
    entry = build(:material_entry, quantity: 0)
    assert_not entry.valid?
  end

  test "requires unit" do
    entry = build(:material_entry, unit: nil)
    assert_not entry.valid?
  end

  test "requires unit_cost_ex_vat_ron" do
    entry = build(:material_entry, unit_cost_ex_vat_ron: nil, unit_cost_inc_vat_ron: nil)
    assert_not entry.valid?
  end

  test "computes total_cost_ex_vat_ron" do
    entry = create(:material_entry, quantity: 10, unit_cost_ex_vat_ron: 50)
    assert_in_delta 500, entry.total_cost_ex_vat_ron, 0.01
  end

  test "computes total_vat_ron" do
    entry = create(:material_entry, quantity: 10, unit_cost_ex_vat_ron: 50, vat_rate: 0.21)
    assert_in_delta 105, entry.total_vat_ron, 0.01
  end

  test "computes total_cost_inc_vat_ron" do
    entry = create(:material_entry, quantity: 10, unit_cost_ex_vat_ron: 50, vat_rate: 0.21)
    assert_in_delta 605, entry.total_cost_inc_vat_ron, 0.01
  end

  test "allows zero vat rate" do
    entry = build(:material_entry, vat_rate: 0)
    assert entry.valid?
  end

  test "rejects invalid vat rate" do
    entry = build(:material_entry, vat_rate: 0.19)
    assert_not entry.valid?
  end

  test "task is optional" do
    entry = build(:material_entry, task: nil)
    assert entry.valid?
  end

  test "soft delete with discard" do
    entry = create(:material_entry)
    entry.discard
    assert entry.discarded?
  end

  # ── VAT input mode ──

  test "ex-vat mode forward-computes unit_cost_inc_vat_ron" do
    entry = create(:material_entry, unit_cost_ex_vat_ron: 100, vat_rate: 0.21)
    assert_in_delta 121.0, entry.unit_cost_inc_vat_ron, 0.01
  end

  test "inc-vat mode back-calculates unit_cost_ex_vat_ron" do
    entry = create(:material_entry,
      vat_input_mode: "inc",
      unit_cost_inc_vat_ron: 121,
      unit_cost_ex_vat_ron: nil,
      vat_rate: 0.21
    )
    assert_in_delta 100.0, entry.unit_cost_ex_vat_ron, 0.01
    assert_in_delta 121.0, entry.unit_cost_inc_vat_ron, 0.01
  end

  test "inc-vat mode computes totals correctly" do
    entry = create(:material_entry,
      vat_input_mode: "inc",
      unit_cost_inc_vat_ron: 121,
      unit_cost_ex_vat_ron: nil,
      quantity: 10,
      vat_rate: 0.21
    )
    assert_in_delta 1000.0, entry.total_cost_ex_vat_ron, 0.01
    assert_in_delta 210.0, entry.total_vat_ron, 0.01
    assert_in_delta 1210.0, entry.total_cost_inc_vat_ron, 0.01
  end

  test "inc-vat mode with zero vat rate" do
    entry = create(:material_entry,
      vat_input_mode: "inc",
      unit_cost_inc_vat_ron: 100,
      unit_cost_ex_vat_ron: nil,
      vat_rate: 0
    )
    assert_in_delta 100.0, entry.unit_cost_ex_vat_ron, 0.01
    assert_in_delta 100.0, entry.unit_cost_inc_vat_ron, 0.01
  end

  test "inc-vat mode rounding" do
    entry = create(:material_entry,
      vat_input_mode: "inc",
      unit_cost_inc_vat_ron: 99.99,
      unit_cost_ex_vat_ron: nil,
      vat_rate: 0.21
    )
    assert_in_delta 82.64, entry.unit_cost_ex_vat_ron, 0.01
  end
end
