# frozen_string_literal: true

module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      resume_session
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      if cookies.signed[:session_id]
        session = Session.find_by(id: cookies.signed[:session_id])
        if session.nil?
          cookies.delete(:session_id)
          return nil
        end
        if session.expired? || !session.user.active? || !session.user.kept?
          session.destroy
          cookies.delete(:session_id)
          return nil
        end
        session
      end
    end

    def request_authentication
      session[:return_to_after_authenticating] = request.fullpath
      redirect_to new_session_path
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session|
        Current.session = session
        cookies.signed[:session_id] = { value: session.id, expires: 30.days.from_now, httponly: true, same_site: :lax, secure: Rails.env.production? }
        enforce_session_limit(user)
      end
    end

    def terminate_session
      Current.session.destroy
      cookies.delete(:session_id)
    end

    MAX_SESSIONS_PER_USER = 5

    def enforce_session_limit(user)
      excess = user.sessions.order(created_at: :desc).offset(MAX_SESSIONS_PER_USER)
      excess.destroy_all if excess.exists?
    end
end
