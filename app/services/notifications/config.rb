# frozen_string_literal: true

module Notifications
  module Config
    module_function

    def sendgrid_api_key
      ENV['SENDGRID_API_KEY'].to_s
    end

    def from_email
      ENV['NOTIFICATION_FROM_EMAIL'].presence || 'no-reply@example.com'
    end

    def from_name
      ENV['NOTIFICATION_FROM_NAME'].presence || 'Singing Cadets'
    end

    def reply_to
      ENV['NOTIFICATION_REPLY_TO'].presence
    end

    def sendgrid_configured?
      sendgrid_api_key.present? && from_email.present?
    end

    def textbelt_api_key
      ENV['TEXTBELT_API_KEY'].to_s
    end

    def textbelt_configured?
      textbelt_api_key.present?
    end
  end
end
