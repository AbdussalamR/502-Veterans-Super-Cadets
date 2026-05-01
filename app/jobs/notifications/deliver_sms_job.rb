# frozen_string_literal: true

module Notifications
  class DeliverSmsJob < ApplicationJob
    queue_as :default

    retry_on StandardError, wait: 30.seconds, attempts: 3 do |_job, error|
      Rails.logger.error "SMS delivery permanently failed: #{error.message}"
      Notifications::AlertDirectors.call(
        message: "An SMS could not be delivered after 3 attempts. Error: #{error.message}"
      )
    end

    def perform(event_key, recipient_id, actor_id = nil, context = {})
      recipient = User.find_by(id: recipient_id)
      return unless recipient
      return unless recipient.sms_deliverable?

      actor = User.find_by(id: actor_id) if actor_id.present?
      sms_text = Notifications::SmsMessageBuilder.build(event_key: event_key, actor: actor, context: context)
      return unless sms_text

      Notifications::SmsDelivery.deliver(recipient: recipient, sms_text: sms_text)
    end
  end
end
