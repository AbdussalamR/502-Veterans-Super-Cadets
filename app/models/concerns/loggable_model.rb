# frozen_string_literal: true

# Concern for adding structured logging to models
module LoggableModel
  extend ActiveSupport::Concern

  # Log a model action
  def log_model_action(action, details = {})
    log_data = {
      action: action,
      model: self.class.name,
      record_id: id,
      timestamp: Time.current.iso8601
    }

    # Add custom details
    log_data.merge!(details) if details.any?

    Rails.logger.info(log_data.to_json)
  end
end

