# frozen_string_literal: true

class ProjectsController < ApplicationController
  before_action :set_project, only: %i[show edit update destroy]

  def index
    authorize Project
    @projects = policy_scope(Project)
      .then { |scope| filter_by_status(scope) }
      .includes(:created_by_user)
      .order(planned_start_date: :desc)
  end

  def show
    authorize @project
    @phases = @project.phases.kept.includes(:tasks).order(planned_start_date: :asc)
    @tasks = @project.tasks.kept.includes(:phase).order(planned_start_date: :asc)
    @daily_log_count     = @project.daily_logs.kept.count
    @material_entry_count = @project.material_entries.kept.count

    @chronological_items = []
    @phases.each do |phase|
      @chronological_items << { type: :phase, item: phase, date: phase.planned_start_date }
    end
    @tasks.each do |task|
      @chronological_items << { type: :task, item: task, date: task.planned_start_date }
    end
    @chronological_items.sort_by! { |item| item[:date] }
  end

  def new
    @project = Project.new
    authorize @project
  end

  def create
    @project = Project.new(project_params)
    @project.created_by_user = Current.user
    authorize @project

    if @project.save
      redirect_to @project, notice: t("common.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @project
    @phases = @project.phases.kept.includes(:tasks).order(planned_start_date: :asc)
    @tasks = @project.tasks.kept.includes(:phase).order(planned_start_date: :asc)
  end

  def update
    authorize @project

    if @project.update(project_params)
      redirect_to @project, notice: t("common.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @project
    @project.discard

    redirect_to projects_path, notice: t("common.deleted")
  end

  private

  def set_project
    @project = Project.kept.find(params[:id])
  end

  def project_params
    params.require(:project).permit(:name, :client_name, :status, :planned_start_date, :planned_end_date, :description)
  end

  def filter_by_status(scope)
    return scope unless params[:status].present?
    return scope unless Project.statuses.key?(params[:status])

    scope.where(status: params[:status])
  end
end
