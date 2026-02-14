# frozen_string_literal: true

class TasksController < ApplicationController
  before_action :set_project, except: :for_project
  before_action :set_task, only: %i[show edit update destroy]

  def show
    authorize @task
  end

  def new
    @task = @project.tasks.build
    authorize @task
  end

  def create
    @task = @project.tasks.build(task_params)
    authorize @task

    if @task.save
      redirect_to project_path(@project), notice: t("common.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @task
  end

  def update
    authorize @task

    if @task.update(task_params)
      redirect_to project_path(@project), notice: t("common.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @task
    @task.discard

    redirect_to project_path(@project), notice: t("common.deleted")
  end

  # GET /tasks_for_project/:project_id — JSON for cascading dropdowns (optional phase_id filter)
  def for_project
    project = Project.kept.find(params[:project_id])
    tasks = project.tasks.kept.order(:name)
    tasks = tasks.where(phase_id: params[:phase_id]) if params[:phase_id].present?
    authorize Task, :index?

    render json: tasks.map { |t| { id: t.id, name: t.name, project_id: t.project_id, phase_id: t.phase_id } }
  end

  private

  def set_project
    @project = Project.kept.find(params[:project_id])
  end

  def set_task
    @task = @project.tasks.kept.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:name, :description, :planned_start_date, :planned_end_date, :status, :priority, :phase_id)
  end
end
