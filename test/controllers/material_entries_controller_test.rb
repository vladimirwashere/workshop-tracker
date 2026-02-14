# frozen_string_literal: true

require "test_helper"

class MaterialEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    setup_roles
    @project = create(:project, :active, created_by_user: @admin)
  end

  # ── Nested (project-scoped) index ──

  test "all roles can list material entries for project" do
    %i[admin owner manager].each do |role|
      user = create(:user, role)
      sign_in user
      get project_material_entries_url(@project)
      assert_response :success, "#{role} should be able to list material entries"
      sign_out
    end
  end

  # ── Nested create ──

  test "admin can create material entry" do
    sign_in @admin

    assert_difference "MaterialEntry.count", 1 do
      post project_material_entries_url(@project), params: {
        material_entry: {
          date: Date.current,
          description: "Cement bags",
          quantity: 50,
          unit: "bags",
          unit_cost_ex_vat_ron: 25.00,
          vat_rate: 0.21,
          supplier_name: "SupplyPro"
        }
      }
    end

    assert_redirected_to project_material_entries_path(@project)
  end

  test "manager can create material entry" do
    sign_in @manager

    assert_difference "MaterialEntry.count", 1 do
      post project_material_entries_url(@project), params: {
        material_entry: {
          date: Date.current,
          description: "Cement bags",
          quantity: 10,
          unit: "bags",
          unit_cost_ex_vat_ron: 5.00,
          vat_rate: 0.21
        }
      }
    end

    assert_redirected_to project_material_entries_path(@project)
  end

  # ── Top-level index (cross-project) ──

  test "all roles can list material entries cross-project" do
    create(:material_entry, project: @project, created_by_user: @admin)

    %i[admin owner manager].each do |role|
      user = create(:user, role)
      sign_in user
      get material_entries_url
      assert_response :success, "#{role} should be able to list cross-project material entries"
      sign_out
    end
  end

  test "top-level index filters by project" do
    other_project = create(:project, :active, created_by_user: @admin)
    entry1 = create(:material_entry, project: @project, created_by_user: @admin, description: "Unique cedar planks")
    entry2 = create(:material_entry, project: other_project, created_by_user: @admin, description: "Special marble tiles")

    sign_in @admin
    get material_entries_url(filter_project_id: @project.id)
    assert_response :success
    assert_includes response.body, entry1.description
    assert_not_includes response.body, entry2.description
  end

  test "top-level index filters by date range" do
    old_entry = create(:material_entry, project: @project, date: 30.days.ago.to_date, created_by_user: @admin, description: "Old lumber")
    recent_entry = create(:material_entry, project: @project, date: Date.current, created_by_user: @admin, description: "Fresh concrete")

    sign_in @admin
    get material_entries_url(from: 7.days.ago.to_date, to: Date.current)
    assert_response :success
    assert_includes response.body, recent_entry.description
    assert_not_includes response.body, old_entry.description
  end

  # ── Top-level new ──

  test "admin can access top-level new material entry form" do
    sign_in @admin
    get new_material_entry_url
    assert_response :success
  end

  test "manager can access top-level new material entry form" do
    sign_in @manager
    get new_material_entry_url
    assert_response :success
  end

  # ── Top-level create ──

  test "admin can create material entry from top-level" do
    sign_in @admin

    assert_difference "MaterialEntry.count", 1 do
      post material_entries_url, params: {
        material_entry: {
          project_id: @project.id,
          date: Date.current,
          description: "Nails box",
          quantity: 5,
          unit: "boxes",
          unit_cost_ex_vat_ron: 12.00,
          vat_rate: 0.21,
          supplier_name: "HardwareDepot"
        }
      }
    end

    assert_redirected_to material_entries_path
  end

  test "manager can create material entry from top-level" do
    sign_in @manager

    assert_difference "MaterialEntry.count", 1 do
      post material_entries_url, params: {
        material_entry: {
          project_id: @project.id,
          date: Date.current,
          description: "Screws pack",
          quantity: 20,
          unit: "packs",
          unit_cost_ex_vat_ron: 3.50,
          vat_rate: 0.21
        }
      }
    end

    assert_redirected_to material_entries_path
  end

  # ── VAT input mode: inc ──

  test "create with inc-vat mode back-calculates ex-vat" do
    sign_in @admin

    assert_difference "MaterialEntry.count", 1 do
      post project_material_entries_url(@project), params: {
        material_entry: {
          date: Date.current,
          description: "Tiles",
          quantity: 5,
          unit: "m²",
          vat_input_mode: "inc",
          unit_cost_inc_vat_ron: 121.00,
          vat_rate: 0.21
        }
      }
    end

    entry = MaterialEntry.last
    assert_in_delta 100.0, entry.unit_cost_ex_vat_ron, 0.01
    assert_in_delta 121.0, entry.unit_cost_inc_vat_ron, 0.01
    assert_in_delta 500.0, entry.total_cost_ex_vat_ron, 0.01
  end

  test "create with ex-vat mode forward-computes inc-vat" do
    sign_in @admin

    assert_difference "MaterialEntry.count", 1 do
      post project_material_entries_url(@project), params: {
        material_entry: {
          date: Date.current,
          description: "Paint",
          quantity: 3,
          unit: "L",
          vat_input_mode: "ex",
          unit_cost_ex_vat_ron: 100.00,
          vat_rate: 0.21
        }
      }
    end

    entry = MaterialEntry.last
    assert_in_delta 100.0, entry.unit_cost_ex_vat_ron, 0.01
    assert_in_delta 121.0, entry.unit_cost_inc_vat_ron, 0.01
  end
end
