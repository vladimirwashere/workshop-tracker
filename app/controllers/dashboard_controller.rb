# frozen_string_literal: true

class DashboardController < ApplicationController
  def show
    authorize :dashboard, :show?

    @generator = ReportGenerator.new(dashboard_params)
    @kpis = @generator.dashboard_kpis
    @date_range = @generator.date_range
@projects = policy_scope(Project).order(:name)

    persist_dashboard_filters
  end

  private

  def dashboard_params
    if params[:from].present? || params[:to].present?
      params.permit(:from, :to, project_ids: [])
    elsif current_user_settings&.last_dashboard_filters.present?
      filters = current_user_settings.last_dashboard_filters
      ActionController::Parameters.new(filters).permit(:from, :to, project_ids: [])
    else
      ActionController::Parameters.new(
        from: Date.current.beginning_of_month.to_s,
        to: Date.current.end_of_month.to_s
      ).permit(:from, :to)
    end
  end

  def persist_dashboard_filters
    return unless Current.user

    sanitized_project_ids = Array(params[:project_ids]).reject(&:blank?).map(&:to_i)
    setting = Current.user.user_setting || Current.user.build_user_setting
    setting.update(
      last_dashboard_filters: {
        from: @date_range.first.to_s,
        to: @date_range.last.to_s,
        project_ids: sanitized_project_ids
      }
    )
  end
end
