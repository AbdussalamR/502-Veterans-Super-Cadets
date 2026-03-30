# frozen_string_literal: true

module Notifications
  class EventReminderJob < ApplicationJob
    queue_as :default

    def perform
      hours = ApplicationSetting.instance.reminder_hours_before
      window_start = Time.current + hours.hours
      window_end   = window_start + 1.hour

      Event.where(date: window_start..window_end, reminder_sent_at: nil).find_each do |event|
        Notifications::Dispatcher.publish(
          event_key: 'event_reminder',
          recipients: Notifications::Audience.approved_members,
          context: Notifications::Payloads.event(event)
        )
        event.update_columns(reminder_sent_at: Time.current)
      end
    end
  end
end
