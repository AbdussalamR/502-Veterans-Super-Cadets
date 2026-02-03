# frozen_string_literal: true

# Concern for adding structured logging to controllers
module Loggable
  extend ActiveSupport::Concern

  # Log an action with user context
  def log_action(action, details = {})
    log_data = {
      action: action,
      controller: controller_name,
      timestamp: Time.current.iso8601,
      request_id: request.request_id
    }

    # Add user context
    if current_user
      log_data[:user] = {
        id: current_user.id,
        email: current_user.email,
        role: current_user.role
      }
    end

    # Add custom details
    log_data.merge!(details) if details.any?

    Rails.logger.info(log_data.to_json)
  end

  # Log successful CRUD operations
  def log_create_success(resource, details = {})
    log_action('create_success', details.merge(
      resource_type: resource.class.name,
      resource_id: resource.id
    ))
  end

  def log_update_success(resource, details = {})
    log_action('update_success', details.merge(
      resource_type: resource.class.name,
      resource_id: resource.id
    ))
  end

  def log_destroy_success(resource, details = {})
    log_action('destroy_success', details.merge(
      resource_type: resource.class.name,
      resource_id: resource.id
    ))
  end

  # Log failures
  def log_create_failure(resource, details = {})
    log_action('create_failure', details.merge(
      resource_type: resource.class.name,
      errors: resource.errors.full_messages
    ))
  end

  def log_update_failure(resource, details = {})
    log_action('update_failure', details.merge(
      resource_type: resource.class.name,
      resource_id: resource.id,
      errors: resource.errors.full_messages
    ))
  end

  # Log authorization/authentication events
  def log_authorization_failure(action, details = {})
    log_action('authorization_failure', details.merge(
      attempted_action: action,
      remote_ip: request.remote_ip
    ))
  end

  def log_authentication_failure(details = {})
    log_action('authentication_failure', details.merge(
      remote_ip: request.remote_ip,
      path: request.fullpath
    ))
  end
end

