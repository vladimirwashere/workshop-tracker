# frozen_string_literal: true

class GanttController < ApplicationController
  PERIOD_DAYS = [ 7, 14, 30, 90, 180, 365 ].freeze

  def show
    authorize :gantt, :show?
    @projects = policy_scope(Project)
      .where.not(status: :cancelled)
      .order(:planned_start_date)
  end

  def data
    authorize :gantt, :show?

    date_from = parse_date(params[:date_from])
    date_to = parse_date(params[:date_to])
    filter_project_ids = Array(params[:project_ids]).reject(&:blank?).map(&:to_i)

    base_projects = policy_scope(Project)
      .where.not(status: :cancelled)
      .order(:planned_start_date)
    base_projects = base_projects.where(id: filter_project_ids) if filter_project_ids.any?
    base_projects = base_projects.to_a
    project_ids = base_projects.map(&:id)

    tasks = policy_scope(Task)
      .where(project_id: project_ids)
      .includes(:phase)
      .order(:planned_start_date)
    if date_from.present? && date_to.present?
      tasks = tasks.where("planned_start_date <= ? AND planned_end_date >= ?", date_to, date_from)
    end
    tasks = tasks.to_a

    task_project_ids = tasks.map(&:project_id).uniq
    @projects = base_projects.select { |p| task_project_ids.include?(p.id) }
    task_ids = tasks.map(&:id)
    phase_ids = tasks.map(&:phase_id).compact.uniq

    @phases_by_project = policy_scope(Phase)
      .where(project_id: @projects.map(&:id), id: phase_ids)
      .order(:planned_start_date)
      .group_by(&:project_id)

    @tasks_by_project = tasks.group_by(&:project_id)
    @tasks_by_phase   = tasks.select(&:phase_id).group_by(&:phase_id)

    render json: {
      projects: @projects.map { |p| project_json(p) }
    }
  end

  def update_task
    authorize :gantt, :update?

    task = Task.kept.find(params[:task_id])
    authorize task, :update?

    start_date = Date.parse(params[:planned_start_date])
    end_date = Date.parse(params[:planned_end_date])

    task.planned_start_date = start_date
    task.planned_end_date = end_date

    if task.save
      render json: { success: true }
    else
      render json: { success: false, error: task.errors.full_messages.join(", ") },
             status: :unprocessable_entity
    end
  rescue Date::Error
    render json: { success: false, error: "Invalid date format." },
           status: :unprocessable_entity
  end

  private

  def project_json(project)
    phases = @phases_by_project[project.id] || []
    all_tasks = @tasks_by_project[project.id] || []
    unphased_tasks = all_tasks.reject(&:phase_id)

    {
      id: project.id,
      name: project.name,
      status: project.status,
      planned_start_date: project.planned_start_date,
      planned_end_date: project.planned_end_date,
      phases: phases.map { |ph| phase_json(ph) },
      tasks: unphased_tasks.map { |t| task_json(t) }
    }
  end

  def phase_json(phase)
    phase_tasks = @tasks_by_phase[phase.id] || []

    {
      id: phase.id,
      name: phase.name,
      status: phase.status,
      planned_start_date: phase.planned_start_date,
      planned_end_date: phase.planned_end_date,
      tasks: phase_tasks.map { |t| task_json(t) }
    }
  end

  def task_json(task)
    {
      id: task.id,
      name: task.name,
      status: task.status,
      planned_start_date: task.planned_start_date,
      planned_end_date: task.planned_end_date,
      phase_id: task.phase_id
    }
  end
end
