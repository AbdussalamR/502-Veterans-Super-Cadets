# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < ApplicationController
    include Loggable
    
    skip_before_action :authenticate_user!

    # Removed passthru method - Omniauth middleware handles the initial redirect

    def google_oauth2
      # Handle both Omniauth and manual OAuth flows
      user = if request.env['omniauth.auth']
               # Standard Omniauth flow
               User.from_google(**from_google_params)
             else
               # Manual OAuth flow - exchange code for user info
               handle_manual_oauth
             end

      if user.present?
        # Check approval status - only allow approved users to sign in
        if user.rejected?
          # User has been rejected
          log_action('oauth_sign_in_rejected', { 
            user_id: user.id, 
            email: user.email, 
            approval_status: 'rejected' 
          })
          flash[:alert] = 'Your registration has been rejected. Please contact an administrator.'
          redirect_to '/users/sign_in'
        elsif user.approved?
          # Manual sign in without Devise helpers
          session[:user_id] = user.id
          log_action('oauth_sign_in_success', { 
            user_id: user.id, 
            email: user.email, 
            role: user.role 
          })
          flash[:success] = 'Successfully signed in with Google!'
          redirect_to root_path
        else
          # User is pending approval
          log_action('oauth_sign_in_pending', { 
            user_id: user.id, 
            email: user.email, 
            approval_status: 'pending' 
          })
          flash[:notice] = "Your registration is pending approval. You'll be notified when approved."
          redirect_to '/users/sign_in'
        end
      else
        log_authentication_failure({ reason: 'user_not_found' })
        flash[:alert] = 'User not authorized to access this application.'
        redirect_to '/users/sign_in'
      end
    rescue StandardError => e
      Rails.logger.error "OAuth error: #{e.message}"
      log_authentication_failure({ 
        reason: 'oauth_error', 
        error_message: e.message,
        error_class: e.class.name
      })
      flash[:alert] = 'Authentication failed. Please try again.'
      redirect_to '/users/sign_in'
    end

    private

    def handle_manual_oauth
      require 'net/http'
      require 'json'

      code = params[:code]
      return nil unless code

      # Exchange authorization code for access token
      token_url = 'https://oauth2.googleapis.com/token'
      client_id = ENV['GOOGLE_CLIENT_ID']
      client_secret = ENV['GOOGLE_CLIENT_SECRET']
      # Environment-aware callback URL
      redirect_uri = oauth_callback_url

      uri = URI(token_url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      req = Net::HTTP::Post.new(uri)
      req.set_form_data({
                          'client_id' => client_id,
                          'client_secret' => client_secret,
                          'code' => code,
                          'grant_type' => 'authorization_code',
                          'redirect_uri' => redirect_uri,
                        })

      response = http.request(req)
      token_data = JSON.parse(response.body)

      return nil unless token_data['access_token']

      # Get user info from Google
      user_info_url = "https://www.googleapis.com/oauth2/v2/userinfo?access_token=#{token_data['access_token']}"
      user_response = Net::HTTP.get_response(URI(user_info_url))
      user_data = JSON.parse(user_response.body)

      # Create user from Google data
      User.from_google(
        email: user_data['email'],
        full_name: user_data['name'],
        uid: user_data['id'],
        avatar_url: user_data['picture']
      )
    end

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

    protected

    def after_omniauth_failure_path_for(_scope)
      new_user_session_path
    end

    def after_sign_in_path_for(resource_or_scope)
      stored_location_for(resource_or_scope) || root_path
    end

    private

    def from_google_params
      @from_google_params ||= {

        uid: auth.uid,

        email: auth.info.email,

        full_name: auth.info.name,

        avatar_url: auth.info.image,

      }
    end

    def auth
      @auth ||= request.env['omniauth.auth']
    end
  end
end
