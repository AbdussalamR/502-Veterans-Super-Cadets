# frozen_string_literal: true

module Notifications
  module Payloads
    module_function

    def event(event)
      {
        'title' => event.title,
        'date_label' => event.date.strftime('%A, %B %-d at %-I:%M %p'),
        'end_time_label' => event.end_time.strftime('%-I:%M %p'),
        'location' => event.location.presence,
        'description' => event.description.presence,
        'event_url' => routes.internal_event_url(event, **url_options),
        'events_url' => routes.internal_events_url(**url_options)
      }
    end

    def event_series(template_event, count:, last_event:)
      {
        'title' => template_event.title,
        'occurrence_count' => count,
        'first_date_label' => template_event.date.strftime('%A, %B %-d at %-I:%M %p'),
        'last_date_label' => last_event.date.strftime('%A, %B %-d at %-I:%M %p'),
        'location' => template_event.location.presence,
        'events_url' => routes.internal_events_url(**url_options)
      }
    end

    def excuse(excuse)
      events = excuse.events.order(:date)

      {
        'excuse_id' => excuse.id,
        'member_name' => excuse.member.full_name,
        'status' => excuse.status,
        'officer_status' => excuse.officer_status,
        'event_summary' => event_summary(events),
        'excuse_url' => routes.internal_excuse_url(excuse, **url_options)
      }
    end

    def demerit(demerit)
      {
        'member_name' => demerit.member.full_name,
        'value' => demerit.value,
        'reason' => demerit.reason,
        'date_label' => demerit.date.strftime('%B %-d, %Y'),
        'member_profile_url' => routes.internal_user_url(demerit.member, **url_options),
        'member_demerits_url' => routes.internal_my_demerits_url(**url_options)
      }
    end

    def performance_request(request)
      {
        'requester_name'  => request.name,
        'organization'    => request.organization,
        'event_date'      => request.event_date.strftime('%B %-d, %Y'),
        'location'        => request.location,
        'contact_email'   => request.contact_email,
        'notes'           => request.notes.presence || 'None',
        'requests_url'    => routes.internal_performance_requests_url(**url_options)
      }
    end

    def user(user)
      {
        'full_name' => user.full_name,
        'email' => user.email,
        'role_display_name' => user.role_display_name,
        'profile_url' => routes.internal_user_url(user, **url_options)
      }
    end

    def event_summary(events)
      count = events.count
      return 'No linked events yet' if count.zero?

      names = events.limit(3).pluck(:title)
      summary = names.join(', ')
      count > names.length ? "#{summary}, and #{count - names.length} more" : summary
    end

    def routes
      Rails.application.routes.url_helpers
    end

    def url_options
      Rails.application.config.action_controller.default_url_options.presence || { host: 'localhost', port: 3000 }
    end
  end
end
