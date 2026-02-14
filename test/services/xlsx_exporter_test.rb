# frozen_string_literal: true

require "test_helper"
require "zip"

class XlsxExporterTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @project = create(:project, :active, created_by_user: @admin)
    @phase = create(:phase, project: @project, name: "Phase One")
    @task = create(:task, project: @project, phase: @phase)
    @worker = create(:worker)
    create(:worker_salary, worker: @worker, gross_monthly_ron: 5000, effective_from: 1.year.ago)

    create(:daily_log, project: @project, task: @task, worker: @worker,
           created_by_user: @admin, hours_worked: 8, log_date: Date.current)
    create(:material_entry, project: @project, task: @task, created_by_user: @admin,
           date: Date.current, description: "Nails", quantity: 200, unit: "pcs",
           unit_cost_ex_vat_ron: 0.1, vat_rate: 0.21)

    @generator = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s
    )
  end

  test "labour_by_project generates valid multi-sheet XLSX" do
    detail = @generator.labour_detail
    xlsx = XlsxExporter.labour_by_project(@generator.labour_by_project, detail: detail)
    assert_valid_xlsx_package!(xlsx, sheet_count: 2)
    assert_no_pivot_helper_sheet(xlsx)
  end

  test "labour_summary generates valid multi-sheet XLSX" do
    detail = @generator.labour_detail
    xlsx = XlsxExporter.labour_summary(@generator.labour_summary, detail: detail)
    assert_valid_xlsx_package!(xlsx, sheet_count: 2)
  end

  test "materials_by_project generates valid multi-sheet XLSX" do
    xlsx = XlsxExporter.materials_by_project(@generator.materials_by_project)
    assert_valid_xlsx_package!(xlsx, sheet_count: 2)
  end

  test "combined_cost generates valid multi-sheet XLSX" do
    labour_detail = @generator.labour_detail
    materials_data = @generator.materials_by_project
    materials_detail = materials_data.flat_map do |row|
      (row[:entries] || []).map do |entry|
        {
          date: entry.date, project_name: row[:project]&.name,
          phase_name: entry.task&.phase&.name, task_name: entry.task&.name,
          description: entry.description, quantity: entry.quantity, unit: entry.unit,
          unit_cost_ex_vat_ron: entry.unit_cost_ex_vat_ron,
          total_cost_ex_vat_ron: entry.total_cost_ex_vat_ron,
          vat_rate: entry.vat_rate, total_vat_ron: entry.total_vat_ron,
          total_cost_inc_vat_ron: entry.total_cost_inc_vat_ron,
          supplier_name: entry.supplier_name
        }
      end
    end

    xlsx = XlsxExporter.combined_cost(
      @generator.combined_cost,
      labour_detail: labour_detail,
      materials_detail: materials_detail
    )
    assert_valid_xlsx_package!(xlsx, sheet_count: 3)
  end

  test "combined_cost supports GBP currency" do
    xlsx = XlsxExporter.combined_cost(@generator.combined_cost, currency: "GBP")
    assert_valid_xlsx_package!(xlsx, sheet_count: 1)
  end

  test "labour_detail returns per-log rows with phase and task names" do
    detail = @generator.labour_detail
    assert detail.any?, "Expected at least one detail row"

    row = detail.first
    assert_equal Date.current, row[:log_date]
    assert_equal @project.name, row[:project_name]
    assert_equal "Phase One", row[:phase_name]
    assert_equal @task.name, row[:task_name]
    assert_equal @worker.full_name, row[:worker_name]
    assert_equal 8.0, row[:hours_worked]
    assert row[:daily_rate_ron] > 0, "Expected a positive daily rate"
    assert row[:cost_ron] > 0, "Expected a positive cost"
  end

  test "XLSX contains formula footer with SUM" do
    xlsx = XlsxExporter.labour_summary(@generator.labour_summary, detail: @generator.labour_detail)

    workbook_xml = extract_xml(xlsx, "xl/worksheets/sheet1.xml")
    assert_match(/SUM/, workbook_xml, "Expected SUM formula in the summary sheet")
  end

  private

  def assert_valid_xlsx_package!(binary, sheet_count: 1)
    assert binary.start_with?("PK"), "Expected XLSX zip signature"

    entry_names = []
    Zip::InputStream.open(StringIO.new(binary)) do |io|
      while (entry = io.get_next_entry)
        entry_names << entry.name
      end
    end

    assert_includes entry_names, "xl/workbook.xml"

    sheet_count.times do |i|
      assert_includes entry_names, "xl/worksheets/sheet#{i + 1}.xml",
        "Expected sheet#{i + 1}.xml in the package"
    end

    assert_includes entry_names, "xl/tables/table1.xml"
  end

  def assert_no_pivot_helper_sheet(binary)
    workbook_xml = extract_xml(binary, "xl/workbook.xml")
    refute_match(/Pivot Helper/, workbook_xml, "Pivot Helper sheet should not exist")
  end

  def extract_xml(binary, path)
    Zip::InputStream.open(StringIO.new(binary)) do |io|
      while (entry = io.get_next_entry)
        return io.read if entry.name == path
      end
    end
    nil
  end
end
