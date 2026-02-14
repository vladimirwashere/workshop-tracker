# frozen_string_literal: true

class ReportsController < ApplicationController
  before_action :set_filter_options

  def financial
    authorize :report, :financial?
    @report_type = params[:report_type] || "labour"

    return unless financial_filters_present?

    @generator = ReportGenerator.new(financial_report_params)
    generate_financial_data

    case params[:format]
    when "xlsx"
      send_xlsx(export_type, xlsx_data)
    when "pdf"
      send_pdf(export_type, pdf_data)
    end
  end

  def activity
    authorize :report, :activity?

    return unless activity_filters_present?

    @generator = ReportGenerator.new(activity_report_params)
    @data = @generator.activity_report
  end

  private

  def financial_filters_present?
    params[:from].present? || params[:to].present? ||
      params[:project_ids].present? || params[:phase_ids].present? ||
      params[:task_ids].present?
  end

  def activity_filters_present?
    params[:from].present? || params[:to].present? ||
      params[:project_ids].present? || params[:phase_ids].present? ||
      params[:task_ids].present? || params[:worker_ids].present?
  end

  def generate_financial_data
    case @report_type
    when "labour"
      if @generator.project_ids.any?
        @data = @generator.labour_by_project
        @labour_display_format = "by_project"
      else
        @data = @generator.labour_summary
        @labour_display_format = "summary"
      end
    when "materials"
      @data = @generator.materials_by_project
    when "combined"
      @data = @generator.combined_cost
    end
  end

  def export_type
    case @report_type
    when "labour"   then "labour_#{@labour_display_format || 'summary'}"
    when "materials" then "materials_by_project"
    when "combined"  then "combined_cost"
    end
  end

  def xlsx_data
    selected_currency = current_currency

    case @report_type
    when "labour"
      detail = @generator.labour_detail
      case @labour_display_format
      when "by_project" then XlsxExporter.labour_by_project(@data, detail: detail, currency: selected_currency)
      else XlsxExporter.labour_summary(@data, detail: detail, currency: selected_currency)
      end
    when "materials" then XlsxExporter.materials_by_project(@data, currency: selected_currency)
    when "combined"
      labour_detail = @generator.labour_detail
      materials_detail = @generator.materials_detail
      XlsxExporter.combined_cost(@data, labour_detail: labour_detail, materials_detail: materials_detail, currency: selected_currency)
    end
  end

  def pdf_data
    date_range = @generator.date_range
    selected_currency = current_currency

    case @report_type
    when "labour"
      case @labour_display_format
      when "by_project" then PdfExporter.labour_by_project(@data, date_range: date_range, currency: selected_currency)
      else PdfExporter.labour_summary(@data, date_range: date_range, currency: selected_currency)
      end
    when "materials" then PdfExporter.materials_by_project(@data, date_range: date_range, currency: selected_currency)
    when "combined"  then PdfExporter.combined_cost(@data, date_range: date_range, currency: selected_currency)
    end
  end

  def set_filter_options
@projects = policy_scope(Project).order(:name)
      @workers = policy_scope(Worker).order(:full_name)

    @selected_project_ids = selected_ids(:project_ids)
    @selected_phase_ids = selected_ids(:phase_ids)
    @selected_task_ids = selected_ids(:task_ids)

    phase_scope = policy_scope(Phase)
    phase_scope = phase_scope.where(project_id: @selected_project_ids) if @selected_project_ids.any?
    @phases = phase_scope.order(:name)

    task_scope = policy_scope(Task)
    task_scope = task_scope.where(project_id: @selected_project_ids) if @selected_project_ids.any?
    task_scope = task_scope.where(phase_id: @selected_phase_ids) if @selected_phase_ids.any?
    @tasks = task_scope.order(:name)
  end

  def selected_ids(key)
    Array(params[key]).reject(&:blank?).map(&:to_i).uniq
  end

  def financial_report_params
    params.permit(:from, :to, project_ids: [], phase_ids: [], task_ids: [])
  end

  def activity_report_params
    params.permit(:from, :to, project_ids: [], phase_ids: [], task_ids: [], worker_ids: [])
  end

  def send_xlsx(type, data)
    send_data data,
              filename: build_filename(type, "xlsx"),
              type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              disposition: "attachment"
  end

  def send_pdf(type, data)
    send_data data, filename: build_filename(type, "pdf"), type: "application/pdf", disposition: "attachment"
  end

  def build_filename(type, ext)
    project_part = if params[:project_ids].present? && params[:project_ids].reject(&:blank?).one?
      project = Project.find_by(id: params[:project_ids].reject(&:blank?).first)
      "_#{project&.name&.parameterize}"
    else
      ""
    end

    "#{type}#{project_part}_#{Date.current.strftime('%d-%m-%Y')}.#{ext}"
  end
end
