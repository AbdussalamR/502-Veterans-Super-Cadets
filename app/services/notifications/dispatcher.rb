# frozen_string_literal: true

module Notifications
  class Dispatcher
    def self.publish(event_key:, recipients:, actor: nil, context: {})
      new(event_key: event_key, recipients: recipients, actor: actor, context: context).publish
    end

    def initialize(event_key:, recipients:, actor:, context:)
      @event_key = event_key.to_s
      @recipients = Array(recipients).flatten.compact
      @actor = actor
      @context = context.deep_stringify_keys
    end

    def publish
      recipients.uniq(&:id).each do |recipient|
        merged_context = context.merge('actor_name' => actor&.full_name)
        Notifications::DeliverNotificationJob.perform_later(event_key, recipient.id, actor&.id, merged_context)
        Notifications::DeliverSmsJob.perform_later(event_key, recipient.id, actor&.id, merged_context)
      end
    end

    private

    attr_reader :event_key, :recipients, :actor, :context
  end
end
