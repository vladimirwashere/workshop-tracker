# frozen_string_literal: true

class PhasesController < ApplicationController
  before_action :set_project, except: :for_project
  before_action :set_phase, only: %i[show edit update destroy]

  def show
    authorize @phase
  end

  def new
    @phase = @project.phases.build
    authorize @phase
  end

  def create
    @phase = @project.phases.build(phase_params)
    authorize @phase

    if @phase.save
      redirect_to @project, notice: t("common.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @phase
  end

  def update
    authorize @phase

    if @phase.update(phase_params)
      redirect_to @project, notice: t("common.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @phase
    @phase.discard

    redirect_to @project, notice: t("common.deleted")
  end

  # GET /phases_for_project/:project_id — JSON for cascading dropdowns
  def for_project
    project = Project.kept.find(params[:project_id])
    phases = project.phases.kept.order(:name)
    authorize Phase, :index?

    render json: phases.map { |p| { id: p.id, name: p.name } }
  end

  private

  def set_project
    @project = Project.kept.find(params[:project_id])
  end

  def set_phase
    @phase = @project.phases.kept.find(params[:id])
  end

  def phase_params
    params.require(:phase).permit(:name, :description, :planned_start_date, :planned_end_date, :status, :priority)
  end
end
