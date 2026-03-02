# app/views/events/index.rss.builder
xml.instruct! :xml, version: '1.0'
xml.rss version: '2.0' do
  xml.channel do
    xml.title 'Cadets Events Feed'
    xml.description 'Upcoming events and activities'
    xml.link internal_events_url
    xml.language 'en-us'
    xml.lastBuildDate Time.current.to_fs(:rfc822)

    @events.each do |event|
      xml.item do
        xml.title event.title
        xml.description do
          parts = []
          parts << "Date: #{event.date.strftime('%B %d, %Y at %I:%M %p')}"
          parts << "End Time: #{event.end_time.strftime('%I:%M %p')}"
          parts << "Location: #{event.location}" if event.location.present?
          parts << event.description if event.description.present?
          parts << 'Self check-in available' if event.allow_self_checkin

          xml.cdata! parts.join("\n\n")
        end
        xml.pubDate event.created_at.to_fs(:rfc822)
        xml.link internal_event_url(event)
        xml.guid internal_event_url(event), isPermaLink: 'true'
        xml.category 'Event'
        xml.category 'Upcoming' if event.date >= Time.zone.today
      end
    end
  end
end
