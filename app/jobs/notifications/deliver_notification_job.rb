# frozen_string_literal: true

module Notifications
  class DeliverNotificationJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 30.seconds, attempts: 3 do |_job, error|
      # All retries exhausted — notify directors and record an in-app alert
      Rails.logger.error "Email delivery permanently failed: #{error.message}"
      Notifications::AlertDirectors.call(
        message: "An email could not be delivered after 3 attempts. Error: #{error.message}"
      )
    end

    def perform(event_key, recipient_id, actor_id = nil, context = {})
      recipient = User.find_by(id: recipient_id)
      return unless recipient

      actor = User.find_by(id: actor_id) if actor_id.present?
      message = Notifications::MessageBuilder.build(event_key:, recipient:, actor:, context:)
      return unless message

      Notifications::EmailDelivery.deliver(recipient:, message:) if recipient.email_deliverable?
    end
  end
end
