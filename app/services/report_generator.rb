# frozen_string_literal: true

class ReportGenerator
  attr_reader :date_range, :project_ids, :phase_ids, :task_ids, :worker_ids

  def initialize(params = {})
    @date_range = parse_date_range(params)
    @project_ids = Array(params[:project_ids]).reject(&:blank?).map(&:to_i)
    @phase_ids = Array(params[:phase_ids]).reject(&:blank?).map(&:to_i)
    @task_ids = Array(params[:task_ids]).reject(&:blank?).map(&:to_i)
    @worker_ids = Array(params[:worker_ids]).reject(&:blank?).map(&:to_i)
  end

  def labour_by_project
    cost_map = daily_rate_cost_allocation

    cost_map.group_by { |entry| entry[:project] }.reject { |k, _| k.nil? }.map do |project, entries|
      workers_grouped = entries.group_by { |e| e[:worker] }.reject { |k, _| k.nil? }.map do |worker, wentries|
        {
          worker: worker,
          days: wentries.map { |e| e[:log_date] }.uniq.count,
          cost_ron: wentries.sum { |e| e[:cost_ron] }.to_f
        }
      end

      {
        project: project,
        total_days: entries.map { |e| [ e[:worker_id], e[:log_date] ] }.uniq.count,
        total_cost_ron: entries.sum { |e| e[:cost_ron] }.to_f,
        workers: workers_grouped
      }
    end
  end

  def labour_summary
    cost_map = daily_rate_cost_allocation

    cost_map.group_by { |entry| entry[:project] }.reject { |k, _| k.nil? }.map do |project, entries|
      {
        project: project,
        total_days: entries.map { |e| [ e[:worker_id], e[:log_date] ] }.uniq.count,
        total_cost_ron: entries.sum { |e| e[:cost_ron] }.to_f
      }
    end
  end

  def materials_by_project
    entries = base_material_entries(:project, { task: :phase })

    entries.group_by(&:project).reject { |k, _| k.nil? }.map do |project, project_entries|
      {
        project: project,
        total_ex_vat_ron: project_entries.sum(&:total_cost_ex_vat_ron).to_f,
        total_vat_ron: project_entries.sum(&:total_vat_ron).to_f,
        total_inc_vat_ron: project_entries.sum(&:total_cost_inc_vat_ron).to_f,
        entries: project_entries
      }
    end
  end

  def combined_cost
    labour = labour_by_project.index_by { |r| r[:project].id }
    materials = materials_by_project.index_by { |r| r[:project].id }

    project_ids_all = (labour.keys + materials.keys).uniq

    project_ids_all.map do |pid|
      project = labour.dig(pid, :project) || materials.dig(pid, :project)
      lab = labour.dig(pid, :total_cost_ron) || 0
      mat_ex = materials.dig(pid, :total_ex_vat_ron) || 0
      mat_vat = materials.dig(pid, :total_vat_ron) || 0
      mat_inc = materials.dig(pid, :total_inc_vat_ron) || 0

      {
        project: project,
        labour_cost_ron: lab.to_f,
        materials_ex_vat_ron: mat_ex.to_f,
        materials_vat_ron: mat_vat.to_f,
        materials_inc_vat_ron: mat_inc.to_f,
        total_ron: (lab + mat_inc).to_f
      }
    end
  end

  def dashboard_kpis
    cost_map = daily_rate_cost_allocation
    materials = base_material_entries
    logs = base_daily_logs

    total_labour = cost_map.sum { |e| e[:cost_ron] }.to_f
    total_materials = materials.sum(&:total_cost_inc_vat_ron).to_f
    total_hours = logs.sum(&:hours_worked).to_f

    top_projects = combined_cost.sort_by { |c| -c[:total_ron] }.first(5)

    {
      total_labour_ron: total_labour,
      total_materials_ron: total_materials,
      total_combined_ron: total_labour + total_materials,
      total_hours: total_hours,
      top_projects: top_projects
    }
  end

  def activity_report
    logs = base_daily_logs(:project, :task, :worker, :attachments)

    logs.sort_by { |l| l.log_date }.reverse.group_by(&:log_date).map do |date, date_logs|
      {
        date: date,
        projects: date_logs.group_by(&:project).reject { |k, _| k.nil? }
          .sort_by { |project, _| project.name }
          .map do |project, project_logs|
          {
            project: project,
            entries: project_logs
              .sort_by { |l| [ l.worker.full_name, l.task.name ] }
              .map do |log|
              {
                worker: log.worker,
                task: log.task,
                hours_worked: log.hours_worked.to_f,
                scope: log.scope,
                attachments: log.attachments.to_a
              }
            end
          }
        end
      }
    end
  end

  # Per-log detail rows with cost allocation, phase/task names, scope, and hours.
  # Used by XLSX detail sheets.
  def labour_detail
    logs = base_daily_logs(:project, { task: :phase }, { worker: :worker_salaries })

    rows = logs.group_by { |l| [ l.worker_id, l.log_date ] }.flat_map do |(worker_id, log_date), day_logs|
      worker = day_logs.first.worker
      daily_rate = worker.daily_rate_cached(log_date) || 0
      share = day_logs.size > 0 ? daily_rate.to_f / day_logs.size : 0

      day_logs.map do |log|
        {
          log_date: log_date,
          project_name: log.project&.name || "Unknown",
          phase_name: log.task&.phase&.name,
          task_name: log.task&.name,
          worker_name: worker.full_name,
          hours_worked: log.hours_worked.to_f,
          scope: log.scope,
          daily_rate_ron: daily_rate.to_f,
          cost_ron: share
        }
      end
    end

    rows.sort_by { |r| [ r[:log_date], r[:project_name], r[:worker_name] ] }
  end

  def materials_detail
    materials_by_project.flat_map do |row|
      project_name = row[:project]&.name || "Unknown"
      (row[:entries] || []).map do |entry|
        {
          date: entry.date,
          project_name: project_name,
          phase_name: entry.task&.phase&.name,
          task_name: entry.task&.name,
          description: entry.description,
          quantity: entry.quantity,
          unit: entry.unit,
          unit_cost_ex_vat_ron: entry.unit_cost_ex_vat_ron,
          total_cost_ex_vat_ron: entry.total_cost_ex_vat_ron,
          vat_rate: entry.vat_rate,
          total_vat_ron: entry.total_vat_ron,
          total_cost_inc_vat_ron: entry.total_cost_inc_vat_ron,
          supplier_name: entry.supplier_name
        }
      end
    end
  end

  private

  def parse_date_range(params)
    from = params[:from].present? ? Date.parse(params[:from].to_s) : Date.current.beginning_of_month
    to = params[:to].present? ? Date.parse(params[:to].to_s) : Date.current.end_of_month
    from..to
  rescue Date::Error
    Date.current.beginning_of_month..Date.current.end_of_month
  end

  # Allocates daily rate costs across log entries per worker-day.
  # Each unique (worker, log_date) pair costs exactly one daily rate,
  # split evenly across that worker's entries for the day.
  def daily_rate_cost_allocation
    logs = base_daily_logs(:project, { worker: :worker_salaries })

    logs.group_by { |l| [ l.worker_id, l.log_date ] }.flat_map do |(worker_id, log_date), day_logs|
      worker = day_logs.first.worker
      daily_rate = worker.daily_rate_cached(log_date) || 0
      share = day_logs.size > 0 ? daily_rate.to_f / day_logs.size : 0

      day_logs.map do |log|
        {
          project: log.project,
          worker: log.worker,
          worker_id: worker_id,
          log_date: log_date,
          cost_ron: share
        }
      end
    end
  end

  def base_daily_logs(*eager_load)
    scope = DailyLog.kept.where(log_date: date_range)
    scope = scope.where(project_id: project_ids) if project_ids.any?
    scope = scope.where(task_id: filtered_task_ids_scope) if task_filtering?
    scope = scope.where(worker_id: worker_ids) if worker_ids.any?

    scope = scope.includes(*eager_load) if eager_load.any?
    scope.to_a
  end

  def base_material_entries(*eager_load)
    scope = MaterialEntry.kept.where(date: date_range)
    scope = scope.where(project_id: project_ids) if project_ids.any?
    scope = scope.where(task_id: filtered_task_ids_scope) if task_filtering?

    scope = scope.includes(*eager_load) if eager_load.any?
    scope.to_a
  end

  def task_filtering?
    phase_ids.any? || task_ids.any?
  end

  def filtered_task_ids_scope
    scope = Task.kept
    scope = scope.where(project_id: project_ids) if project_ids.any?
    scope = scope.where(phase_id: phase_ids) if phase_ids.any?
    scope = scope.where(id: task_ids) if task_ids.any?
    scope.select(:id)
  end
end
