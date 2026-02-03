# frozen_string_literal: true

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
           ENV['GOOGLE_CLIENT_ID'],
           ENV['GOOGLE_CLIENT_SECRET'],
           {
             scope: 'email,profile',
             prompt: 'select_account',
             image_aspect_ratio: 'square',
             image_size: 50,
             skip_jwt: true,
           }
end

# Configure Omniauth to handle CSRF protection
OmniAuth.config.allowed_request_methods = %i[post get]
OmniAuth.config.silence_get_warning = true

# Add failure handling
OmniAuth.config.on_failure = proc do |env|
  OmniAuth::FailureEndpoint.new(env).redirect_to_failure
end
