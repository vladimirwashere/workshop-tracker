# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_after_action :verify_authorized

  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: t("sessions.rate_limited") }

  layout "auth"

  def new
    redirect_to dashboard_path if authenticated?
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])

    if user&.active? && user&.kept?
      start_new_session_for user
      redirect_to after_authentication_url, notice: t("sessions.signed_in")
    else
      log_failed_login(params[:email_address])
      flash.now[:alert] = t("sessions.invalid_credentials")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, status: :see_other, notice: t("sessions.signed_out")
  end

  private

  def log_failed_login(email)
    user = User.find_by(email_address: email)
    return unless user

    AuditLog.create!(
      auditable: user,
      action: "failed_login",
      changes_data: { reason: user.kept? && user.active? ? "bad_password" : "account_disabled" },
      ip_address: request.remote_ip
    )
  rescue StandardError => e
    Rails.logger.error("[Security] Failed to log failed login: #{e.message}")
  end
end
