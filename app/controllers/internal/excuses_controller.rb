module Internal
  class ExcusesController < InternalController
    include Loggable

    before_action :authenticate_user!
    before_action :set_excuse, only: %i[show update review cancel_recurring]
    
    # AC 3: Block unauthorized URL access with 403 Forbidden
    before_action :ensure_section_access, only: %i[show update review cancel_recurring]

    def index
      # AC 2: Section-based filtering
      base_query = if current_user.super_admin?
                     Excuse
                   elsif current_user.officer?
                     Excuse.joins(:member).where(users: { section_id: current_user.section_id })
                   else
                     current_user.excuses
                   end

      @excuses = base_query
        .includes(:member, :events, :reviewers)
        .order(Arel.sql("CASE status
           WHEN 'Pending Section Leader Review' THEN 0
           WHEN 'pending' THEN 1
           WHEN 'denied' THEN 2
           WHEN 'approved' THEN 3
           ELSE 4 END ASC, submission_date DESC"))
    end

    def new
      @excuse = Excuse.new
    end

    def create
      @excuse = current_user.excuses.build(excuse_params)
      @excuse.manual_event_ids = params[:excuse][:event_ids]
      @excuse.submission_date = Time.current

      if @excuse.save
        log_create_success(@excuse, { recurring: @excuse.recurring? })
        redirect_to internal_excuses_path, notice: "Excuse submitted successfully for Officer review."
      else
        log_create_failure(@excuse)
        render :new, status: :unprocessable_entity
      end
    end

    def update
      if current_user.super_admin?
        if @excuse.finalize_by_admin(current_user, params[:status])
          log_action('excuse_finalized', { excuse_id: @excuse.id, status: @excuse.status })
          redirect_to internal_excuse_path(@excuse), notice: "Director finalized decision as #{@excuse.status}."
        else
          redirect_to internal_excuse_path(@excuse), alert: "Invalid decision."
        end
      elsif current_user.officer?
        unless @excuse.status == 'Pending Section Leader Review'
          return redirect_to internal_excuse_path(@excuse), alert: "This excuse has already been processed and cannot be updated."
        end

        success = ActiveRecord::Base.transaction do
          @excuse.set_officer_decision(current_user, params[:status]) &&
            @excuse.update(status: 'pending')
        end

        if success
          log_action('excuse_provisionally_processed', { excuse_id: @excuse.id })
          redirect_to internal_excuse_path(@excuse), notice: "Officer decision recorded."
        else
          redirect_to internal_excuse_path(@excuse), alert: "Invalid decision."
        end
      else
        render plain: "403 Forbidden", status: :forbidden
      end
    end

    def review
      if @excuse.add_reviewer(current_user)
        log_action('excuse_seconded', { excuse_id: @excuse.id, reviewer_id: current_user.id })
        redirect_to internal_excuse_path(@excuse), notice: 'Marked as reviewed.'
      else
        redirect_to internal_excuse_path(@excuse), alert: 'You have already reviewed this excuse.'
      end
    end

    def cancel_recurring
      @excuse.cancel_future_events!
      log_action('recurring_excuse_cancelled', { excuse_id: @excuse.id })
      redirect_to internal_excuse_path(@excuse), notice: "Future events cancelled."
    end

    private

    def set_excuse
      @excuse = Excuse.find(params[:id])
    end

    def ensure_section_access
      return if current_user.super_admin?

      if current_user.officer?
        if current_user.section_id != @excuse.member.section_id
          render plain: "403 Forbidden - You are not the Officer for this member's section.", status: :forbidden and return
        end
      elsif @excuse.member != current_user
        render plain: "403 Forbidden", status: :forbidden and return
      end
    end

    def excuse_params
      params.require(:excuse).permit(:reason, :proof_link, :recurring, :start_date, :end_date, :recurring_days,
                                     :recurring_start_time, :recurring_end_time, { event_ids: [] })
    end
  end
end