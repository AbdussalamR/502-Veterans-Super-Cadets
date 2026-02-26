class ExcusesController < ApplicationController
  include Loggable

  before_action :authenticate_user!
  before_action :set_excuse, only: [:show, :update, :review, :cancel_recurring]

  def index
    if current_user.admin? || current_user.officer?
      @excuses = Excuse
        .includes(:member, :events, :reviewers)
        .order(Arel.sql("
          CASE status
            WHEN 'pending' THEN 0
            WHEN 'denied' THEN 1
            WHEN 'approved' THEN 2
            ELSE 3
          END ASC,
          submission_date DESC
        "))
    else
      @excuses = current_user.excuses
        .includes(:events, :reviewers)
        .order(Arel.sql("
          CASE status
            WHEN 'pending' THEN 0
            WHEN 'denied' THEN 1
            WHEN 'approved' THEN 2
            ELSE 3
          END ASC,
          submission_date DESC
        "))
    end
  end

  def show
    # @excuse is set by before_action
  end

  def new
    @excuse = Excuse.new
  end

  def create
    # build from permitted attrs but exclude event_ids and reviewed_by_id while building record
    @excuse = current_user.excuses.build(excuse_params.except(:event_ids, :reviewed_by_id))
    @excuse.status = 'pending'
    @excuse.submission_date = Time.current

    # Handle recurring excuses
    if @excuse.recurring?
      @excuse.frequency = 'weekly'

      # Find matching events based on recurring pattern
      matching_events = @excuse.find_matching_events

      # AC5: If no events match, show a helpful message
      if matching_events.empty?
        flash.now[:alert] = "No scheduled events match your selected days (#{@excuse.recurring_day_names}) between #{@excuse.start_date.strftime('%B %d, %Y')} and #{@excuse.end_date.strftime('%B %d, %Y')}. Please adjust your selection."
        render :new and return
      end

      if @excuse.save
        matching_events.each { |event| @excuse.events << event }

        log_create_success(@excuse, { event_ids: @excuse.event_ids, member_id: current_user.id, recurring: true })
        redirect_to excuses_path, notice: "Recurring excuse submitted! Applied to #{matching_events.size} event(s)."
      else
        log_create_failure(@excuse)
        render :new
      end
    else
      # Save first so join records can reference a persisted excuse
      if @excuse.save
        # Attach multiple events if provided (support both single :event_id for backward compatibility)
        if excuse_params[:event_ids].present?
          Array(excuse_params[:event_ids]).each do |eid|
            event = Event.find_by(id: eid)
            @excuse.events << event if event
          end
        elsif excuse_params[:event_id].present?
          event = Event.find_by(id: excuse_params[:event_id])
          @excuse.events << event if event
        end

        if excuse_params[:reviewed_by_id].present?
          @excuse.reviewed_by_id = excuse_params[:reviewed_by_id]
          @excuse.save
        end

        log_create_success(@excuse, { event_ids: @excuse.event_ids, member_id: current_user.id })
        redirect_to excuses_path, notice: 'Excuse submitted!'
      else
        log_create_failure(@excuse)
        render :new
      end
    end
  end

  def update
    if current_user.super_admin?
      # Admin finalizes decision (sets final status)
      old_status = @excuse.status
      final_status = params[:status]
      unless %w[approved denied].include?(final_status)
        redirect_to excuse_path(@excuse), alert: 'Invalid status' and return
      end

      @excuse.finalize_by_admin(current_user, final_status)

      # Only update attendance when final status becomes approved
      if final_status == 'approved'
        # For each event associated with this excuse, mark attendance as excused
        @excuse.events.find_each do |ev|
          attendance = Attendance.find_or_initialize_by(
            event_id: ev.id,
            user_id: @excuse.member_id
          )
          attendance.status = 'excused'
          attendance.note = "Excused - Approved excuse ##{@excuse.id}"
          attendance.save
        end
      elsif old_status == 'approved' && final_status != 'approved'
        # Revert attendance for all events previously excused by this excuse
        @excuse.events.find_each do |ev|
          attendance = Attendance.find_by(
            event_id: ev.id,
            user_id: @excuse.member_id
          )
          if attendance && attendance.status == 'excused'
            attendance.status = 'absent'
            attendance.note = "Excuse was #{final_status}"
            attendance.save
          end
        end
      end

      log_action('excuse_finalized', { excuse_id: @excuse.id, final_status: final_status, admin_id: current_user.id })
      redirect_to excuse_path(@excuse), notice: "Excuse #{final_status}."

    elsif current_user.officer?
      # Officer makes a provisional decision; does NOT change final status
      prov_status = params[:status]
      unless %w[approved denied].include?(prov_status)
        redirect_to excuse_path(@excuse), alert: 'Invalid provisional status' and return
      end

      @excuse.set_officer_decision(current_user, prov_status)

      log_action('excuse_provisionally_processed', {
        excuse_id: @excuse.id,
        officer_id: current_user.id,
        provisional_status: prov_status
      })

      redirect_to excuse_path(@excuse), notice: "Officer decision recorded — awaiting admin finalization."
    else
      log_authorization_failure('review_excuse', { excuse_id: @excuse.id })
      redirect_to excuses_path, alert: 'Not authorized.'
    end
  end

  # POST /excuses/:id/review
  # Adds the current officer/admin as a reviewer (a "second"). Does not change status.
  def review
    unless current_user.admin? || current_user.officer?
      log_authorization_failure('second_excuse', { excuse_id: @excuse.id })
      redirect_to excuses_path, alert: 'Not authorized.' and return
    end

    unless %w[approved denied].include?(@excuse.status)
      redirect_to excuse_path(@excuse), alert: 'Only processed (approved/denied) excuses may be reviewed.' and return
    end

    if @excuse.reviewers.exists?(id: current_user.id)
      redirect_to excuse_path(@excuse), notice: 'You have already reviewed this excuse.' and return
    end

    @excuse.add_reviewer(current_user)
    @excuse.save

    log_action('excuse_seconded', {
      excuse_id: @excuse.id,
      reviewer_id: current_user.id,
      status: @excuse.status
    })

    redirect_to excuse_path(@excuse), notice: 'Marked as reviewed.'
  end

  # POST /excuses/:id/cancel_recurring
  # AC6: Members can cancel future recurring excuses
  def cancel_recurring
    unless @excuse.member_id == current_user.id || current_user.admin?
      redirect_to excuses_path, alert: 'Not authorized.' and return
    end

    unless @excuse.recurring?
      redirect_to excuse_path(@excuse), alert: 'This is not a recurring excuse.' and return
    end

    removed_count = @excuse.events.where('date > ?', Time.current).count
    @excuse.cancel_future_events!

    log_action('recurring_excuse_cancelled', { excuse_id: @excuse.id, removed_events: removed_count })
    redirect_to excuse_path(@excuse), notice: "Cancelled #{removed_count} future event(s) from this recurring excuse."
  end

  private

  def set_excuse
    @excuse = Excuse.find(params[:id])
  end

  def excuse_params
    # accept a link to proof instead of an uploaded file
    # allow event_ids array for multiple events
    params.require(:excuse).permit(:event_id, { event_ids: [] }, :reason, :proof_link, :reviewed_by_id,
                                   :recurring, :start_date, :end_date, :recurring_days)
  end
end