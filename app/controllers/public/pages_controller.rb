# frozen_string_literal: true

module Public
  class PagesController < PublicController
    def home
      @home_photos = MediaPhoto.for_page('home').published_only.ordered
    end

    def performance_request
      @performance_request = PerformanceRequest.new
    end

    def submit_performance_request
      @performance_request = PerformanceRequest.new(
        name: params[:performance_request][:name].to_s.strip,
        organization: params[:performance_request][:organization].to_s.strip,
        event_date: params[:performance_request][:event_date],
        location: params[:performance_request][:location].to_s.strip,
        contact_email: params[:performance_request][:contact_email].to_s.strip,
        notes: params[:performance_request][:notes].to_s.strip
      )

      if @performance_request.save
        # Notify all directors via the shared SendGrid notification system
        Notifications::Dispatcher.publish(
          event_key: 'performance_request_submitted',
          recipients: Notifications::Audience.approved_super_admins,
          actor: nil,
          context: Notifications::Payloads.performance_request(@performance_request)
        )
        redirect_to public_performance_request_path,
                    notice: "Thank you, #{@performance_request.name}! Your performance request has been submitted. We'll be in touch soon."
      else
        render :performance_request, status: :unprocessable_entity
      end
    end

    def media_gallery
      @media_photos = MediaPhoto.for_page('media').published_only.ordered
      @media_videos = MediaVideo.published_only.ordered
    end

    def audition_information
      now = Time.current
      @current_auditions = AuditionSession.where('start_datetime <= ? AND end_datetime >= ?', now, now).chronological
      @future_auditions = AuditionSession.where('start_datetime > ?', now).chronological
      @past_auditions = AuditionSession.where(end_datetime: ...now).chronological
    end

    def calendar
      @events = Event.where(is_public: true)

      respond_to do |format|
        format.html
        format.json do
          render json: @events.map { |e|
            {
              id: e.id,
              title: e.title,
              start: e.date,
              end: e.end_time,
              description: e.description,
              location: e.location,
              url: e.ticket_url,
              backgroundColor: '#500000',
              borderColor: '#500000',
            }
          }
        end
      end
    end

    def contact; end

    def submit_contact
      @msg = ContactMessage.new(
        name: params[:name].to_s.strip,
        email: params[:email].to_s.strip,
        message: params[:message].to_s.strip
      )

      if @msg.save
        redirect_to public_contact_path, notice: "Thank you, #{@msg.name}! Your message has been sent."
      else
        redirect_to public_contact_path,
                    alert: "Could not send message: #{@msg.errors.full_messages.to_sentence}"
      end
    end
  end
end
