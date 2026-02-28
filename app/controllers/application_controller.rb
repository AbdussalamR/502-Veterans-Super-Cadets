# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception, except: [:omniauth_callback]
  before_action :authenticate_user!, unless: :skip_authentication?
  before_action :set_lograge_user_context

  private

  # Provide user context to lograge for structured logging
  def set_lograge_user_context
    return unless defined?(Lograge)

    # Store data for lograge to pick up in custom_options
    request.env['lograge.current_user'] = current_user if current_user
    request.env['lograge.session_id'] = session.id
    request.env['lograge.remote_ip'] = request.remote_ip
    request.env['lograge.host'] = request.host
  end

  # Override to add custom payload information for Rails instrumentation
  def append_info_to_payload(payload)
    super
    payload[:current_user] = current_user if current_user
    payload[:session_id] = session.id if session
    payload[:remote_ip] = request.remote_ip
    payload[:host] = request.host
  end

  def authenticate_user!
    return if user_signed_in?

    # Log authentication failure
    Rails.logger.info({
      action: 'authentication_required',
      path: request.fullpath,
      remote_ip: request.remote_ip,
      timestamp: Time.current.iso8601
    }.to_json)

    session[:return_to] = request.fullpath if request.get?
    redirect_to '/users/sign_in', alert: 'Please sign in to continue.'
  end

  def user_signed_in?
    current_user.present?
  end

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = session[:user_id] ? User.find_by(id: session[:user_id]) : nil
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  helper_method :current_user, :user_signed_in?

  def ensure_admin
    authenticate_user!
    return if performed?
    return if current_user&.admin?

    redirect_to root_path, alert: 'You must be an admin to access this page.'
  end

  def ensure_super_admin
    authenticate_user!
    return if performed?
    return if current_user&.super_admin?

    redirect_to root_path, alert: 'You must be a super admin to access this page.'
  end

  def skip_authentication?
    # Auth controllers always skip
    return true if controller_name == 'auth' || (controller_name == 'omniauth_callbacks' && controller_path.include?('users'))
  
    # Allow Event index (Feeds) ONLY if a valid token is provided
    return User.exists?(calendar_token: params[:token]) if controller_name == 'events' && action_name == 'index' && params[:token].present?

    false
  end
end
