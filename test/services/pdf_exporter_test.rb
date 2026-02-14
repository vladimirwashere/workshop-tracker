# frozen_string_literal: true

require "test_helper"

class PdfExporterTest < ActiveSupport::TestCase
  setup do
    @admin = create(:user, :admin)
    @project = create(:project, :active, created_by_user: @admin)
    @task = create(:task, project: @project)
    @worker = create(:worker)
    create(:worker_salary, worker: @worker, gross_monthly_ron: 5000, effective_from: 1.year.ago)

    create(:daily_log, project: @project, task: @task, worker: @worker,
           created_by_user: @admin, hours_worked: 8, log_date: Date.current)
    create(:material_entry, project: @project, task: @task, created_by_user: @admin,
           date: Date.current, description: "Bolts", quantity: 50, unit: "pcs",
           unit_cost_ex_vat_ron: 2.0, vat_rate: 0.21)

    @generator = ReportGenerator.new(
      from: Date.current.beginning_of_month.to_s,
      to: Date.current.end_of_month.to_s
    )
    @date_range = @generator.date_range
  end

  test "labour_by_project generates valid PDF" do
    pdf = PdfExporter.labour_by_project(@generator.labour_by_project, date_range: @date_range)
    assert pdf.is_a?(String)
    assert pdf.start_with?("%PDF")
  end

  test "labour_summary generates valid PDF" do
    pdf = PdfExporter.labour_summary(@generator.labour_summary, date_range: @date_range)
    assert pdf.start_with?("%PDF")
  end

  test "materials_by_project generates valid PDF" do
    pdf = PdfExporter.materials_by_project(@generator.materials_by_project, date_range: @date_range)
    assert pdf.start_with?("%PDF")
  end

  test "combined_cost generates valid PDF" do
    pdf = PdfExporter.combined_cost(@generator.combined_cost, date_range: @date_range)
    assert pdf.start_with?("%PDF")
  end

  test "combined_cost generates valid GBP PDF" do
    pdf = PdfExporter.combined_cost(@generator.combined_cost, date_range: @date_range, currency: "GBP")
    assert pdf.start_with?("%PDF")
  end

  test "PDF handles empty data" do
    gen = ReportGenerator.new(from: "2020-01-01", to: "2020-01-31")
    pdf = PdfExporter.labour_summary(gen.labour_summary, date_range: gen.date_range)
    assert pdf.start_with?("%PDF")
  end
end
