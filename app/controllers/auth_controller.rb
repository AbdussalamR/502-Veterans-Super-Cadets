# frozen_string_literal: true

class AuthController < ApplicationController
  include Loggable
  
  skip_before_action :authenticate_user!

  def sign_in
    # Simple sign-in page that just shows OAuth options
    # No Devise mapping needed since this is a regular controller
  end

  def create
    # Redirect any form submissions to the sign-in page
    redirect_to '/auth/sign_in', alert: 'Please use Google OAuth to sign in.'
  end

  def destroy
    # Sign out - clear session and redirect
    if user_signed_in?
      user_info = { user_id: current_user.id, email: current_user.email }
      session[:user_id] = nil
      log_action('user_sign_out', user_info)
      flash[:notice] = 'Signed out successfully.'
    end
    redirect_to '/users/sign_in'
  end

  def oauth_redirect
  # Only use environment variables - do not hardcode IDs
  client_id = ENV['GOOGLE_CLIENT_ID']
  
  if client_id.blank?
    redirect_to '/users/sign_in', alert: "Google Client ID is missing in the environment variables."
    return
  end

  redirect_uri = oauth_callback_url

  google_auth_url = 'https://accounts.google.com/o/oauth2/v2/auth?' \
                    "client_id=#{client_id}&" \
                    "redirect_uri=#{CGI.escape(redirect_uri)}&" \
                    'response_type=code&' \
                    'scope=email%20profile&' \
                    'access_type=offline&' \
                    'prompt=select_account'

  redirect_to google_auth_url, allow_other_host: true
end

  
  private

  def oauth_callback_url
    # Environment-aware callback URL
    if Rails.env.development?
      # In development, use localhost to match Google OAuth app config
      'http://localhost:3000/auth/google_oauth2/callback'
    else
      # In production, use the actual host (Heroku, etc.)
      "#{request.protocol}#{request.host}/auth/google_oauth2/callback"
    end
  end
end
