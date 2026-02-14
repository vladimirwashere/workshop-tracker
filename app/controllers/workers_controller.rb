# frozen_string_literal: true

class WorkersController < ApplicationController
  before_action :set_worker, only: %i[show edit update destroy]

  def index
    authorize Worker
    scope = policy_scope(Worker).includes(:worker_salaries)

    if params[:search].present?
      scope = scope.where("full_name ILIKE ?", "%#{Worker.sanitize_sql_like(params[:search])}%")
    end

    scope = scope.order(:full_name)
    @pagy, @workers = paginate_or_load_all(scope)
  end

  def show
    authorize @worker
    @can_view_salary = policy(@worker).view_salary?
    @current_salary = @worker.current_salary if @can_view_salary
    @salary_history = @worker.worker_salaries.kept.order(effective_from: :desc) if @can_view_salary
  end

  def new
    @worker = Worker.new
    authorize @worker
  end

  def create
    @worker = Worker.new(worker_params)
    authorize @worker

    if @worker.save
      redirect_to @worker, notice: t("common.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @worker
  end

  def update
    authorize @worker

    if @worker.update(worker_params)
      redirect_to @worker, notice: t("common.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @worker
    @worker.discard

    redirect_to workers_path, notice: t("common.deleted")
  end

  private

  def set_worker
    @worker = Worker.kept.find(params[:id])
  end

  def worker_params
    params.require(:worker).permit(:full_name, :trade, :active, :notes)
  end
end
