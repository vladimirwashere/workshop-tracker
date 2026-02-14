# frozen_string_literal: true

class UserSettingsController < ApplicationController
  def update
    setting = Current.user.user_setting || Current.user.build_user_setting
    authorize setting, :update?

    if setting.update(user_settings_params)
      respond_to do |format|
        format.json { render json: { ok: true, currency: setting.default_currency_display }, status: :ok }
        format.turbo_stream { redirect_back fallback_location: root_path, notice: t("user_settings.updated") }
        format.html { redirect_back fallback_location: root_path, notice: t("user_settings.updated") }
      end
    else
      respond_to do |format|
        format.json { render json: { ok: false, error: t("user_settings.update_failed") }, status: :unprocessable_entity }
        format.turbo_stream { redirect_back fallback_location: root_path, alert: t("user_settings.update_failed") }
        format.html { redirect_back fallback_location: root_path, alert: t("user_settings.update_failed") }
      end
    end
  end

  private

  def user_settings_params
    params.require(:user_setting).permit(
      :default_currency_display, :last_gantt_zoom,
      last_dashboard_filters: [ :from, :to, project_ids: [] ]
    )
  end
end
