# frozen_string_literal: true

class WorkerTimelinesController < ApplicationController
  def index
    authorize :worker_timeline, :index?
    @workers = policy_scope(Worker).active_workers.order(:full_name)
  end

  def show
    authorize :worker_timeline, :show?

    @worker = Worker.kept.find(params[:worker_id])

    respond_to do |format|
      format.html
      format.json { render json: timeline_data }
    end
  end

  private

  def timeline_data
    logs = @worker.daily_logs.kept
      .includes(:project, :task, { worker: :worker_salaries })
      .order(:log_date)

    # Count logs per day to split daily rate evenly
    day_counts = logs.group_by(&:log_date).transform_values(&:count)

    entries = logs.map do |dl|
      entry = {
        project_id: dl.project_id,
        project_name: dl.project.name,
        task_id: dl.task_id,
        task_name: dl.task.name,
        date: dl.log_date,
        hours: dl.hours_worked.to_f
      }

      if can_view_costs?
        daily_rate = dl.worker.daily_rate_cached(dl.log_date) || 0
        share = day_counts[dl.log_date] > 0 ? daily_rate.to_f / day_counts[dl.log_date] : 0
        entry[:cost] = share.round(2)
      end

      entry
    end

    { worker: @worker.full_name, logs: entries }
  end

  def can_view_costs?
    Current.user&.admin? || Current.user&.owner? || Current.user&.manager?
  end
end
