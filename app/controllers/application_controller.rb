# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization
  include Pagy::Backend

  # When a list has more than this many rows, use pagination (this many per page).
  PAGINATION_THRESHOLD = 50

  rate_limit to: 300, within: 1.minute, by: -> { request.remote_ip }, with: -> { head :too_many_requests }

  allow_browser versions: :modern
  stale_when_importmap_changes

  before_action :set_time_zone
  after_action :verify_authorized
  after_action :verify_policy_scoped, if: -> { action_name == "index" }

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  helper_method :current_user, :current_user_settings, :current_currency

  private

  def current_user
    Current.user
  end

  def pundit_user
    Current.user
  end

  def set_time_zone
    Time.zone = "Bucharest"
  end

  def current_user_settings
    return nil unless Current.user

    @current_user_settings ||= Current.user.user_setting
  end

  def current_currency
    current_user_settings&.default_currency_display || "RON"
  end

  def user_not_authorized
    flash[:alert] = t("common.not_authorized")
    redirect_back(fallback_location: root_path)
  end

  def record_not_found
    flash[:alert] = t("common.record_not_found")
    redirect_back(fallback_location: root_path)
  end

  # Returns [pagy_or_nil, records]. Use when count > PAGINATION_THRESHOLD to paginate (50 per page), else load all.
  def paginate_or_load_all(scope)
    count = scope.limit(PAGINATION_THRESHOLD + 1).count
    if count <= PAGINATION_THRESHOLD
      [nil, scope.to_a]
    else
      pagy(scope, items: PAGINATION_THRESHOLD)
    end
  end

  def parse_date(value)
    return nil unless value.present?

    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end

  def after_authentication_url
    path = session.delete(:return_to_after_authenticating)
    return path if safe_redirect_path?(path)

    if Current.user&.admin? || Current.user&.owner? || Current.user&.manager?
      dashboard_path
    else
      root_path
    end
  end

  def safe_redirect_path?(path)
    path.present? && path.start_with?("/") && !path.start_with?("//") && URI.parse(path).host.nil?
  rescue URI::InvalidURIError
    false
  end
end
