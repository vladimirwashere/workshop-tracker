# frozen_string_literal: true

class DailyLogsController < ApplicationController
  include CreatesAttachmentsFromParams

  before_action :set_daily_log, only: %i[show edit update destroy]

  def index
    authorize DailyLog

    @date_from = parse_date(params[:from]) || Date.current
    @date_to = parse_date(params[:to]) || @date_from

    @daily_logs = policy_scope(DailyLog)
                    .in_range(@date_from, @date_to)
                    .includes(:project, :task, :worker)
                    .order(:log_date, :worker_id)
    @pagy, @daily_logs = paginate_or_load_all(@daily_logs)
  end

  def show
    authorize @daily_log
  end

  def new
    @daily_log = DailyLog.new(log_date: params[:log_date] || Date.current, hours_worked: 8)
    apply_session_defaults_to_new_log
    authorize @daily_log
    load_form_collections
  end

  def create
    @daily_log = DailyLog.new(daily_log_params)
    @daily_log.created_by_user = Current.user
    authorize @daily_log

    if @daily_log.save
      persist_session_defaults
      redirect_to daily_logs_path(from: @daily_log.log_date, to: @daily_log.log_date),
                  notice: notice_with_attachments(t("daily_logs.created"), @daily_log)
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @daily_log
    load_form_collections
  end

  def update
    authorize @daily_log

    if @daily_log.update(daily_log_params)
      persist_session_defaults
      redirect_to daily_logs_path(from: @daily_log.log_date, to: @daily_log.log_date),
                  notice: notice_with_attachments(t("daily_logs.updated"), @daily_log)
    else
      load_form_collections
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @daily_log
    @daily_log.discard

    redirect_to daily_logs_path(from: @daily_log.log_date, to: @daily_log.log_date), notice: t("daily_logs.deleted")
  end

  def duplicate
    authorize DailyLog, :create?
    source = DailyLog.kept.find(params[:daily_log_id])
    authorize source, :show?

    @daily_log = source.dup
    @daily_log.assign_attributes(created_by_user: Current.user, discarded_at: nil)

    if @daily_log.save
      persist_session_defaults
      redirect_to daily_logs_path(from: @daily_log.log_date, to: @daily_log.log_date), notice: t("daily_logs.duplicated")
    else
      load_form_collections
      render :new, status: :unprocessable_entity
    end
  end

  private

  def set_daily_log
    @daily_log = DailyLog.kept.find(params[:id])
  end

  def daily_log_params
    params.require(:daily_log).permit(:project_id, :task_id, :worker_id, :log_date, :hours_worked, :scope)
  end

  def load_form_collections
    @projects = policy_scope(Project).active_projects.order(:name)
    @workers = policy_scope(Worker).active_workers.order(:full_name)
    @phases = if @daily_log&.project_id.present?
                policy_scope(Phase).where(project_id: @daily_log.project_id).order(:name)
              else
                Phase.none
              end
    @tasks = if @daily_log&.project_id.present?
               policy_scope(Task).where(project_id: @daily_log.project_id).order(:name)
              else
               Task.none
              end
    @phase_id_filter = @daily_log.task&.phase_id
  end

  def apply_session_defaults_to_new_log
    return if params[:project_id].present? || params[:task_id].present?

    @daily_log.project_id = session[:last_daily_log_project_id] if session[:last_daily_log_project_id].present?
    @daily_log.task_id = session[:last_daily_log_task_id] if session[:last_daily_log_task_id].present?
    @daily_log.worker_id = session[:last_daily_log_worker_id] if session[:last_daily_log_worker_id].present?
  end

  def persist_session_defaults
    session[:last_daily_log_project_id] = @daily_log.project_id
    session[:last_daily_log_task_id] = @daily_log.task_id
    session[:last_daily_log_worker_id] = @daily_log.worker_id
    session[:last_daily_log_phase_id] = @daily_log.task&.phase_id
  end

end
