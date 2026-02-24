# frozen_string_literal: true

class AttendancesController < ApplicationController
  include Loggable
  
  before_action :ensure_admin, only: %i[new create update]
  before_action :set_event, only: %i[new create update self_checkin_form self_checkin]
  before_action :authenticate_user!, only: %i[self_checkin_form self_checkin]

  # Shows the attendance taking interface for a specific event (SCRUM-64)
  def new
    @users = User.approved.order(:full_name)
    @attendances = @event.attendances.index_by(&:user_id)
    @excused_user_ids = @event.approved_excuses.pluck(:member_id)

    # Pre-populate absent status for users without attendance records
    # Pre-populate excused status for users with approved excuses
    @users.each do |user|
      unless @attendances[user.id]
        if @excused_user_ids.include?(user.id)
          @attendances[user.id] = @event.attendances.build(user: user, status: 'excused')
        else
          @attendances[user.id] = @event.attendances.build(user: user, status: 'absent')
        end
      end
    end
  end

  # Saves attendance records for multiple users (SCRUM-66)
  def create
    ActiveRecord::Base.transaction do
      params[:attendances].each do |user_id, attendance_params|
        attendance = @event.attendances.find_or_initialize_by(user_id: user_id)
        attendance.status = attendance_params[:status]
        attendance.note = attendance_params[:note] if attendance_params[:note].present?
        attendance.save!
      end
    end

    log_action('attendance_recorded', { 
      event_id: @event.id, 
      event_title: @event.title,
      attendance_count: params[:attendances].keys.size 
    })

    # SCRUM-67: Confirmation message
    flash[:success] = 'Attendance has been recorded successfully.'
    redirect_to @event
  rescue StandardError => e
    log_action('attendance_record_failure', { 
      event_id: @event.id, 
      error: e.message 
    })
    flash.now[:error] = "Error recording attendance: #{e.message}"
    @users = User.approved.order(:full_name)
    @attendances = @event.attendances.index_by(&:user_id)
    @excused_user_ids = @event.approved_excuses.pluck(:member_id)
    render :new
  end

  # For updating attendance later if needed
  def update
    redirect_to new_internal_event_attendance_path(@event)
  end

  # Shows the self-checkin form for members
  def self_checkin_form
    unless @event.allow_self_checkin?
      flash[:error] = 'Self check-in is not enabled for this event.'
      redirect_to internal_events_path and return
    end

    unless @event.self_checkin_available?
      flash[:error] = 
        'Self check-in is not currently available for this event. Check-in is only available from 10 minutes before to 10 minutes after the event.'
      redirect_to internal_events_path and return
    end

    # Check if user already checked in
    existing_attendance = @event.attendances.find_by(user: current_user)
    if existing_attendance
      flash[:notice] = 'You have already checked in for this event.'
      redirect_to internal_events_path and return
    end
  end

  # Processes self-checkin with passcode verification
  def self_checkin
    unless @event.allow_self_checkin?
      flash[:error] = 'Self check-in is not enabled for this event.'
      redirect_to internal_events_path and return
    end

    unless @event.self_checkin_available?
      flash[:error] = 
        'Self check-in is not currently available for this event. Check-in is only available from 10 minutes before to 10 minutes after the event.'
      redirect_to self_checkin_internal_event_path(@event) and return
    end

    # Check if user already checked in
    existing_attendance = @event.attendances.find_by(user: current_user)
    if existing_attendance
      flash[:notice] = 'You have already checked in for this event.'
      redirect_to internal_events_path and return
    end

    # Verify passcode
    passcode = params[:passcode]
    unless @event.verify_passcode(passcode)
      flash[:error] = 'Invalid passcode. Please try again.'
      redirect_to self_checkin_internal_event_path(@event) and return
    end

    # Create attendance record
    attendance = @event.attendances.build(user: current_user, status: 'present')
    if attendance.save
      log_action('self_checkin_completed', {
        event_id: @event.id,
        event_title: @event.title,
        user_id: current_user.id,
        user_name: current_user.full_name
      })
      flash[:success] = 'Successfully checked in!'
      redirect_to internal_events_path
    else
      flash[:error] = "Error checking in: #{attendance.errors.full_messages.join(', ')}"
      redirect_to self_checkin_internal_event_path(@event)
    end
  end

  private

  def set_event
    @event = Event.find(params[:event_id] || params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:error] = 'Event not found'
    redirect_to internal_events_path
  end
end
