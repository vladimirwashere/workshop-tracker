# frozen_string_literal: true

class MaterialEntriesController < ApplicationController
  include CreatesAttachmentsFromParams

  before_action :set_project, if: -> { params[:project_id].present? }
  before_action :set_material_entry, only: %i[show edit update destroy]

  def index
    authorize MaterialEntry

    if @project
      scope = policy_scope(@project.material_entries)
    else
      @date_from = parse_date(params[:from]) || Date.current.beginning_of_month
      @date_to = parse_date(params[:to]) || Date.current.end_of_month
      @projects = policy_scope(Project).order(:name)

      scope = policy_scope(MaterialEntry)
      scope = scope.where(project_id: params[:filter_project_id]) if params[:filter_project_id].present?
      scope = scope.where(date: @date_from..@date_to)
    end

    scope = scope.includes(:project, :task, :created_by_user).order(date: :desc)
    @pagy, @material_entries = paginate_or_load_all(scope)
  end

  def show
    authorize @material_entry
  end

  def new
    defaults = { date: Date.current, vat_rate: MaterialEntry::DEFAULT_VAT_RATE, vat_input_mode: "inc" }
    if @project
      @material_entry = @project.material_entries.new(defaults)
    else
      @material_entry = MaterialEntry.new(defaults)
      load_projects
    end
    authorize @material_entry
    load_form_collections
  end

  def create
    if @project
      @material_entry = @project.material_entries.new(material_entry_params)
    else
      @material_entry = MaterialEntry.new(material_entry_params)
    end
    @material_entry.created_by_user = Current.user
    authorize @material_entry

    if @material_entry.save
      redirect_to(@project ? project_material_entries_path(@project) : material_entries_path,
                  notice: notice_with_attachments(t("material_entries.created"), @material_entry))
    else
      load_projects unless @project
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @material_entry
    @material_entry.vat_input_mode = "inc"
    load_form_collections
  end

  def update
    authorize @material_entry

    if @material_entry.update(material_entry_params)
      redirect_to project_material_entry_path(@project, @material_entry),
                  notice: notice_with_attachments(t("material_entries.updated"), @material_entry)
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @material_entry
    @material_entry.discard

    redirect_to project_material_entries_path(@project), notice: t("material_entries.deleted")
  end

  private

  def set_project
    @project = Project.kept.find(params[:project_id])
  end

  def set_material_entry
    @material_entry = @project.material_entries.kept.find(params[:id])
  end

  def material_entry_params
    permitted = %i[
      task_id date description quantity unit
      unit_cost_ex_vat_ron unit_cost_inc_vat_ron vat_rate
      vat_input_mode supplier_name
    ]
    permitted << :project_id unless @project
    params.require(:material_entry).permit(*permitted)
  end

  def load_form_collections
    if @project
      @tasks = policy_scope(Task).where(project_id: @project.id).order(:name)
    elsif @material_entry&.project_id.present?
      @tasks = policy_scope(Task).where(project_id: @material_entry.project_id).order(:name)
    else
      @tasks = Task.none
    end
  end

  def load_projects
    @projects = policy_scope(Project).order(:name)
  end
end
