# frozen_string_literal: true

class EventsController < ApplicationController
  include Loggable
  
  before_action :set_event, only: %i[show edit update destroy]
  before_action :ensure_admin, only: %i[new create edit update destroy]

  rescue_from ActionController::RoutingError, with: :handle_routing_error

  # GET /events or /events.json
  def index
    # simple order by upcoming to past
    # @events = Event.order(date: :desc)

    # If we ever want to separate upcoming and past events:
    @upcoming_events = Event.upcoming.order(date: :asc)
    @past_events     = Event.past.order(date: :desc)
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

    if @event.repeat_weekly.to_s == "1" && @event.repeat_until.present?
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
        format.html { redirect_to @event, notice: 'Event was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @event }
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
      format.html { redirect_to events_path, notice: 'Event was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def save_single_event(event)
    respond_to do |format|
      if @event.save
        log_create_success(@event, { event_title: @event.title, event_date: @event.date })
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        log_create_failure(@event)
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  def create_recurring_events(template_event)
    repeat_until_str = template_event.repeat_until.to_s.strip
    repeat_until = Date.parse(repeat_until_str) rescue nil

    unless repeat_until
      flash[:alert] = "Invalid repeat until date."
      return render :new, status: :unprocessable_entity
    end

    start_date = template_event.date.to_date
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

    log_create_success(template_event, { event_title: "#{template_event.title} (and #{events.size - 1} more)", event_date: template_event.date })

    respond_to do |format|
      format.html { redirect_to events_path, notice: "#{events.size} events were successfully created." }
      format.json { render json: { created_events: events.size }, status: :created }
    end
  end


  # Use callbacks to share common setup or constraints between actions.
  def set_event
    @event = Event.find(params[:id])
  end

  # Only allow a list of trusted parameters through.
  def event_params
    params.require(:event).permit(:title, :date, :end_time, :location, :description, :allow_self_checkin, :repeat_weekly, :repeat_until)
  end

  def handle_routing_error
    flash[:alert] = "You tried to access a page that doesn't exist or requires admin permissions."
    redirect_to events_path
  end
end
