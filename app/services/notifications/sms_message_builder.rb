# frozen_string_literal: true

module Notifications
  class SmsMessageBuilder
    def self.build(event_key:, actor:, context:)
      new(event_key: event_key, actor: actor, context: context).build
    end

    def initialize(event_key:, actor:, context:)
      @event_key = event_key.to_s
      @actor = actor
      @context = context
    end

    def build
      case event_key
      when 'registration_pending_admin'
        "New member pending approval: #{context['full_name']} (#{context['email']})."
      when 'registration_approved'
        "#{actor_name} approved your Singing Cadets registration. You can now sign in."
      when 'registration_rejected'
        "#{actor_name} rejected your registration. Contact leadership if this is a mistake."
      when 'role_promoted_to_officer', 'role_promoted_to_super_admin',
           'role_demoted_to_officer', 'role_demoted_to_user'
        "#{actor_name} updated your role to #{context['role_display_name']}."
      when 'event_created'
        event_sms("New event", include_description: true)
      when 'event_updated'
        event_sms("Updated event", include_description: false)
      when 'event_reminder'
        event_sms("Reminder", include_description: false)
      when 'event_cancelled'
        text = "Canceled: #{context['title']} on #{context['date_label']}"
        text += " at #{context['location']}" if context['location'].present?
        "#{text}."
      when 'event_series_created'
        text = "#{context['occurrence_count']} new events: #{context['title']}. " \
               "#{context['first_date_label']} through #{context['last_date_label']}"
        text += " at #{context['location']}" if context['location'].present?
        "#{text}."
      when 'performance_request_submitted'
        org_line = "#{context['requester_name']} (#{context['organization']})"
        "New performance request from #{org_line} on #{context['event_date']} at #{context['location']}."
      when 'excuse_submitted_for_review'
        "#{context['member_name']} submitted an excuse for section review. Events: #{context['event_summary']}."
      when 'excuse_submitted_for_director_review'
        "#{context['member_name']} submitted a personal excuse for director review. Events: #{context['event_summary']}."
      when 'excuse_pending_admin_review'
        "Excuse from #{context['member_name']} ready for director review. " \
        "Officer decision: #{context['officer_status']}. Events: #{context['event_summary']}."
      when 'excuse_approved'
        "#{actor_name} approved your excuse. Events: #{context['event_summary']}."
      when 'excuse_denied'
        "#{actor_name} denied your excuse. Events: #{context['event_summary']}."
      when 'demerit_created'
        "#{actor_name} assigned #{context['value']} discipline point(s) on " \
        "#{context['date_label']}. Reason: #{context['reason']}."
      when 'demerit_updated'
        "#{actor_name} updated your discipline record on #{context['date_label']}. Reason: #{context['reason']}."
      when 'demerit_deleted'
        "#{actor_name} removed a discipline record. Reason: #{context['reason']}."
      end
    end

    private

    attr_reader :event_key, :actor, :context

    def actor_name
      actor&.full_name || context['actor_name'] || 'A Cadets admin'
    end

    def event_sms(prefix, include_description:)
      text = "#{prefix}: #{context['title']} on #{context['date_label']} to #{context['end_time_label']}"
      text += " at #{context['location']}" if context['location'].present?
      text += ". #{context['description']}" if include_description && context['description'].present?
      "#{text}."
    end
  end
end
