# frozen_string_literal: true

module Internal
  class EventsController < InternalController
    include Loggable

    before_action :set_event, only: %i[show edit update destroy]
    before_action :ensure_admin, only: %i[new create edit update destroy]
    skip_before_action :ensure_admin, only: %i[index show] # Allow public access to feeds

    rescue_from ActionController::RoutingError, with: :handle_routing_error

    # GET /events or /events.json or /events.ics or /events.rss
    def index
      @upcoming_events = Event.upcoming.order(date: :asc)
      @past_events     = Event.past.order(date: :desc)
      @events = @upcoming_events # For feeds, use upcoming events

      respond_to do |format|
        format.html  # Your existing HTML view
        format.ics { render_calendar }
        format.rss   # Renders index.rss.builder
      end
    end

    # GET /events/1 or /events/1.json
    def show; end

    # GET /events/new
    def new
      @event = Event.new
    end

    # GET /events/1/edit
    def edit; end

    # POST /events or /events.json
    def create
      @event = Event.new(event_params)

      if @event.repeat_weekly.to_s == '1' && @event.repeat_until.present?
        create_recurring_events(@event)
      else
        save_single_event(@event)
      end
    end

    # PATCH/PUT /events/1 or /events/1.json
    def update
      respond_to do |format|
        if @event.update(event_params)
          log_update_success(@event, { event_title: @event.title, event_date: @event.date })
          format.html { redirect_to internal_event_path(@event), notice: 'Event was successfully updated.', status: :see_other }
          format.json { render :show, status: :ok, location: internal_event_url(@event) }
        else
          log_update_failure(@event)
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /events/1 or /events/1.json
    def destroy
      event_title = @event.title
      @event.destroy
      log_destroy_success(@event, { event_title: event_title })

      respond_to do |format|
        format.html do
          redirect_to internal_events_path, notice: 'Event was successfully destroyed.', status: :see_other
        end
        format.json { head :no_content }
      end
    end

    private

    def render_calendar
      calendar = Icalendar::Calendar.new
      calendar.prodid = '-//Cadets Events//EN'
      calendar.x_wr_calname = 'Cadets Events Calendar'

      @events.each do |event|
        calendar.add_event(event.to_ical_event)
      end

      render plain: calendar.to_ical, content_type: 'text/calendar'
    end

    def save_single_event(_event)
      respond_to do |format|
        if @event.save
          log_create_success(@event, { event_title: @event.title, event_date: @event.date })
          format.html { redirect_to internal_event_path(@event), notice: 'Event was successfully created.' }
          format.json { render :show, status: :created, location: internal_event_url(@event) }
        else
          log_create_failure(@event)
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @event.errors, status: :unprocessable_entity }
        end
      end
    end

    def create_recurring_events(template_event)
      repeat_until_str = template_event.repeat_until.to_s.strip
      repeat_until = begin
        Date.parse(repeat_until_str)
      rescue StandardError
        nil
      end

      unless repeat_until
        flash[:alert] = 'Invalid repeat until date.'
        return render :new, status: :unprocessable_entity
      end

      template_event.date.to_date
      events = []
      current_start = template_event.date
      current_end = template_event.end_time

      while current_start.to_date <= repeat_until
        events << template_event.dup.tap do |e|
          e.date = current_start
          e.end_time = current_end
        end
        current_start += 1.week
        current_end += 1.week
      end

      events.each(&:save!)

      log_create_success(template_event,
                         { event_title: "#{template_event.title} (and #{events.size - 1} more)",
                           event_date: template_event.date, })

      respond_to do |format|
        format.html { redirect_to internal_events_path, notice: "#{events.size} events were successfully created." }
        format.json { render json: { created_events: events.size }, status: :created }
      end
    end

    def set_event
      @event = Event.find(params[:id])
    end

    def event_params
      params.require(:event).permit(:title, :date, :end_time, :location, :description, :allow_self_checkin,
                                    :repeat_weekly, :repeat_until)
    end

    def handle_routing_error
      flash[:alert] = "You tried to access a page that doesn't exist or requires admin permissions."
      redirect_to internal_events_path
    end
  end
end
