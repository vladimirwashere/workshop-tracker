# frozen_string_literal: true

class WorkerSalariesController < ApplicationController
  before_action :set_worker
  before_action :set_worker_salary, only: %i[edit update destroy]

  def index
    authorize WorkerSalary
    @worker_salaries = policy_scope(@worker.worker_salaries).order(effective_from: :desc)
  end

  def new
    @worker_salary = @worker.worker_salaries.build
    authorize @worker_salary
  end

  def create
    @worker_salary = @worker.worker_salaries.build(worker_salary_params)
    authorize @worker_salary

    if @worker_salary.save
      redirect_to worker_worker_salaries_path(@worker), notice: t("common.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @worker_salary
  end

  def update
    authorize @worker_salary

    if @worker_salary.update(worker_salary_params)
      redirect_to worker_worker_salaries_path(@worker), notice: t("common.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @worker_salary
    @worker_salary.discard

    redirect_to worker_worker_salaries_path(@worker), notice: t("common.deleted")
  end

  private

  def set_worker
    @worker = Worker.kept.find(params[:worker_id])
  end

  def set_worker_salary
    @worker_salary = @worker.worker_salaries.kept.find(params[:id])
  end

  def worker_salary_params
    params.require(:worker_salary).permit(:gross_monthly_ron, :effective_from)
  end
end
