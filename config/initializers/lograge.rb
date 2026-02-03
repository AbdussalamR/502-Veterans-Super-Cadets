# frozen_string_literal: true

Rails.application.configure do
  # Enable lograge for structured logging
  config.lograge.enabled = true

  # Use JSON format for logs
  config.lograge.formatter = Lograge::Formatters::Logstash.new

  # Include additional custom data in logs
  config.lograge.custom_options = lambda do |event|
    exceptions = %w[controller action format id]
    
    # Base log data
    data = {
      params: event.payload[:params].except(*exceptions),
      time: Time.current
    }

    # Add host and remote_ip from payload or request env
    data[:host] = event.payload[:host] if event.payload[:host]
    data[:remote_ip] = event.payload[:remote_ip] if event.payload[:remote_ip]

    # Add user context if available
    if event.payload[:current_user]
      user = event.payload[:current_user]
      data[:user] = {
        id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: user.role,
        approval_status: user.approval_status
      }
    else
      data[:user] = { authenticated: false }
    end

    # Add exception details if present
    if event.payload[:exception]
      exception_class, message = event.payload[:exception]
      data[:exception] = {
        class: exception_class,
        message: message
      }
    end

    # Add additional context if available
    data[:session_id] = event.payload[:session_id] if event.payload[:session_id]
    data[:request_id] = event.payload[:request_id] if event.payload[:request_id]

    data
  end

  # Log to stdout in production if RAILS_LOG_TO_STDOUT is set
  if ENV['RAILS_LOG_TO_STDOUT'].present?
    config.lograge.logger = ActiveSupport::Logger.new($stdout)
  end

  # Keep logging SQL queries in development
  unless Rails.env.production?
    config.lograge.keep_original_rails_log = true
  end
end

