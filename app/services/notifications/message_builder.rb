# frozen_string_literal: true

module Notifications
  class MessageBuilder
    Message = Struct.new(
      :subject,
      :heading,
      :intro,
      :bullets,
      :cta_label,
      :cta_url,
      keyword_init: true
    )

    def self.build(event_key:, recipient:, actor:, context:)
      new(event_key:, recipient:, actor:, context:).build
    end

    def initialize(event_key:, recipient:, actor:, context:)
      @event_key = event_key.to_s
      @recipient = recipient
      @actor = actor
      @context = context
    end

    def build
      case event_key
      when 'registration_pending_admin'
        message(
          subject: 'New member registration pending approval',
          heading: 'A new member needs approval',
          intro: "#{context['full_name']} signed in and is waiting for approval.",
          bullets: ["Email: #{context['email']}"],
          cta_label: 'Review registrations',
          cta_url: admin_registrations_url
        )
      when 'registration_approved'
        message(
          subject: 'Your Singing Cadets registration was approved',
          heading: 'Registration approved',
          intro: "#{actor_name} approved your registration.",
          bullets: ['You can now sign in and view events, excuses, and attendance tools.'],
          cta_label: 'Open your profile',
          cta_url: context['profile_url']
        )
      when 'registration_rejected'
        message(
          subject: 'Your Singing Cadets registration was rejected',
          heading: 'Registration rejected',
          intro: "#{actor_name} rejected your registration.",
          bullets: ['Contact Cadets leadership if you believe this was a mistake.'],
          cta_label: 'Contact the team',
          cta_url: public_contact_url
        )
      when 'role_promoted_to_officer', 'role_promoted_to_super_admin', 'role_demoted_to_officer', 'role_demoted_to_user'
        message(
          subject: "Your role changed to #{context['role_display_name']}",
          heading: 'Role updated',
          intro: "#{actor_name} changed your role to #{context['role_display_name']}.",
          bullets: ["Current role: #{context['role_display_name']}"],
          cta_label: 'View your profile',
          cta_url: context['profile_url']
        )
      when 'event_created'
        message(
          subject: "#{context['title']} was added to the calendar",
          heading: 'New event scheduled',
          intro: "#{actor_name} added a new event.",
          bullets: event_bullets,
          cta_label: 'View event',
          cta_url: context['event_url']
        )
      when 'event_updated'
        message(
          subject: "#{context['title']} was updated",
          heading: 'Event updated',
          intro: "#{actor_name} updated an event on the calendar.",
          bullets: event_bullets,
          cta_label: 'View event',
          cta_url: context['event_url']
        )
      when 'event_cancelled'
        message(
          subject: "#{context['title']} was canceled",
          heading: 'Event canceled',
          intro: "#{actor_name} canceled an event.",
          bullets: [
            "When: #{context['date_label']}",
            ("Where: #{context['location']}" if context['location'].present?)
          ],
          cta_label: 'View calendar',
          cta_url: context['events_url']
        )
      when 'event_series_created'
        message(
          subject: "#{context['title']} recurring series was added",
          heading: 'Recurring event series scheduled',
          intro: "#{actor_name} added #{context['occurrence_count']} events to the calendar.",
          bullets: [
            "Series: #{context['title']}",
            "First event: #{context['first_date_label']}",
            "Last event: #{context['last_date_label']}",
            ("Where: #{context['location']}" if context['location'].present?)
          ],
          cta_label: 'View calendar',
          cta_url: context['events_url']
        )
      when 'excuse_submitted_for_review'
        message(
          subject: 'A new excuse needs section review',
          heading: 'New excuse submitted',
          intro: "#{context['member_name']} submitted an excuse for review.",
          bullets: ["Events: #{context['event_summary']}"],
          cta_label: 'Review excuse',
          cta_url: context['excuse_url']
        )
      when 'excuse_pending_admin_review'
        message(
          subject: 'An excuse is ready for director review',
          heading: 'Excuse awaiting final decision',
          intro: "#{actor_name} recorded a section decision and moved an excuse to director review.",
          bullets: [
            "Member: #{context['member_name']}",
            "Section decision: #{context['officer_status']}",
            "Events: #{context['event_summary']}"
          ],
          cta_label: 'Review excuse',
          cta_url: context['excuse_url']
        )
      when 'excuse_approved', 'excuse_denied'
        decision = event_key.split('_').last
        message(
          subject: "Your excuse was #{decision}",
          heading: "Excuse #{decision}",
          intro: "#{actor_name} #{decision} your excuse.",
          bullets: ["Events: #{context['event_summary']}"],
          cta_label: 'View excuse',
          cta_url: context['excuse_url']
        )
      when 'demerit_created'
        message(
          subject: 'You received discipline points',
          heading: 'Discipline points assigned',
          intro: "#{actor_name} assigned discipline points to your record.",
          bullets: demerit_bullets,
          cta_label: 'View your profile',
          cta_url: context['member_profile_url']
        )
      when 'demerit_updated'
        message(
          subject: 'Your discipline record was updated',
          heading: 'Discipline record updated',
          intro: "#{actor_name} updated a discipline record on your profile.",
          bullets: demerit_bullets,
          cta_label: 'View your profile',
          cta_url: context['member_profile_url']
        )
      when 'demerit_deleted'
        message(
          subject: 'A discipline record was removed from your profile',
          heading: 'Discipline record removed',
          intro: "#{actor_name} removed a discipline record from your profile.",
          bullets: demerit_bullets,
          cta_label: 'View your discipline points',
          cta_url: context['member_demerits_url']
        )
      end
    end

    private

    attr_reader :event_key, :recipient, :actor, :context

    def message(subject:, heading:, intro:, bullets:, cta_label:, cta_url:)
      Message.new(
        subject:,
        heading:,
        intro:,
        bullets: Array(bullets).compact_blank,
        cta_label:,
        cta_url:
      )
    end

    def event_bullets
      [
        "When: #{context['date_label']} to #{context['end_time_label']}",
        ("Where: #{context['location']}" if context['location'].present?),
        ("Details: #{context['description']}" if context['description'].present?)
      ]
    end

    def demerit_bullets
      [
        "Value: #{context['value']}",
        "Date: #{context['date_label']}",
        "Reason: #{context['reason']}"
      ]
    end

    def actor_name
      actor&.full_name || context['actor_name'] || 'A Cadets admin'
    end
    def admin_registrations_url
      routes.admin_registrations_url(**url_options)
    end

    def public_contact_url
      routes.public_contact_url(**url_options)
    end

    def routes
      Rails.application.routes.url_helpers
    end

    def url_options
      Rails.application.config.action_controller.default_url_options.presence || { host: 'localhost', port: 3000 }
    end
  end
end
