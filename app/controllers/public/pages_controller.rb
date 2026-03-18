# frozen_string_literal: true

module Public
  class PagesController < PublicController
    def home; end

    def performance_request; end

    def media_gallery; end

    def audition_information
      @audition_sessions = AuditionSession.all
    end

    def calendar
      @events = Event.where(is_public: true)
      
      respond_to do |format|
        format.html # Renders the page
        format.json do # Sends the data to the calendar
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
  end
end
