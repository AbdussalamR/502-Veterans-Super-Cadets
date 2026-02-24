# frozen_string_literal: true

module Users
  class SessionsController < Devise::SessionsController
    def after_sign_out_path_for(_resource_or_scope)
      '/public/home'
    end

    def after_sign_in_path_for(resource_or_scope)
      stored_location_for(resource_or_scope) || root_path
    end

    # Only allow OAuth sign in, disable regular email/password
    def create
      redirect_to '/users/sign_in', alert: 'Please use Google OAuth to sign in.'
    end
  end
end
