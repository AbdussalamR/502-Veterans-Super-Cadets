# frozen_string_literal: true

module Public
  class PagesController < PublicController
    def home
      @home_photos = MediaPhoto.for_page('home').published_only.ordered
    end

    def performance_request; end

    def media_gallery
      @media_photos = MediaPhoto.for_page('media').published_only.ordered
      @media_videos = MediaVideo.published_only.ordered
    end

    def audition_information
      now = Time.current
      @current_auditions = AuditionSession.where('start_datetime <= ? AND end_datetime >= ?', now, now).chronological
      @future_auditions = AuditionSession.where('start_datetime > ?', now).chronological
      @past_auditions = AuditionSession.where('end_datetime < ?', now).chronological
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
        name:    params[:name].to_s.strip,
        email:   params[:email].to_s.strip,
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
