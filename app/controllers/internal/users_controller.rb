# frozen_string_literal: true

module Internal
  class UsersController < InternalController
    include Loggable
  
    before_action :authenticate_user!
    before_action :ensure_admin, except: %i[show attendance_history edit update]
    before_action :set_user,
                  only: %i[show edit update promote_to_officer promote_to_super_admin demote_to_user demote_to_officer
                           attendance_history destroy]
    before_action :ensure_can_edit_user!, only: %i[edit update]

    def index
      # 1. Base query with eager loading to prevent N+1 performance issues
      @all_filtered_users = User.includes(:section, :attendances).order(:full_name)

      # 2. Handle search functionality
      if params[:search].present?
        search_term = params[:search].strip.downcase
        @all_filtered_users = @all_filtered_users.where(
          'LOWER(full_name) LIKE ? OR LOWER(email) LIKE ?',
          "%#{search_term}%",
          "%#{search_term}%"
        )
      end

      # 3. Handle role filtering
      @all_filtered_users = @all_filtered_users.where(role: params[:role]) if params[:role].present?

      # 4. Partition users into logical groups for the hierarchical view
      # Convert to array to avoid re-running queries in the view
      users_array = @all_filtered_users.to_a

      # Group A: Directors (Super Admins) - Always at the top
      @directors = users_array.select(&:super_admin?)

      # Group B: Everyone else (to be grouped by section in the view)
      @non_directors = users_array.reject(&:super_admin?)

      # Fetch sections for iteration
      @sections = Section.order(:name)

      # Store search parameters for form persistence
      @search_term = params[:search]
      @selected_role = params[:role]
    end

    def show
      # Users can view their own profile, admins and officers can view any profile
      if @user == current_user || current_user.admin? || current_user.officer?
        # Calculate attendance statistics for the profile
        @total_events = @user.attendances.count
        @total_present = @user.attendances.where(status: ['present', 'tardy']).count
        @total_tardies = @user.attendances.tardy.count
        @total_tardies_and_demerits = @total_tardies + @user.received_demerits.sum(:value)
      else
        log_authorization_failure('view_user_profile', { target_user_id: @user.id })
        redirect_to root_path, alert: 'You are not authorized to view this profile.'
        nil
      end
    end

    def edit
      # Only admins can edit user information
    end

    def update
      if @user.update(user_params)
        log_update_success(@user, { updated_fields: user_params.keys })
        redirect_to internal_user_path(@user), notice: 'User information updated successfully.'
      else
        log_update_failure(@user)
        render :edit
      end
    end

    def promote_to_officer
      ensure_super_admin
      return if performed?

      @user.promote_to_officer!(promoted_by: current_user)
      Notifications::Dispatcher.publish(
        event_key: 'role_promoted_to_officer',
        recipients: [@user],
        actor: current_user,
        context: Notifications::Payloads.user(@user)
      )
      log_action('user_promoted_to_officer', { 
                   target_user_id: @user.id, 
                   target_user_email: @user.email 
                 })
      redirect_to internal_users_path, notice: "#{@user.full_name} has been promoted to officer."
    rescue StandardError => e
      log_action('user_promotion_failed', { 
                   target_user_id: @user.id, 
                   error: e.message 
                 })
      redirect_to internal_users_path, alert: e.message
    end

    def promote_to_super_admin
      ensure_super_admin
      return if performed?

      @user.promote_to_super_admin!(promoted_by: current_user)
      Notifications::Dispatcher.publish(
        event_key: 'role_promoted_to_super_admin',
        recipients: [@user],
        actor: current_user,
        context: Notifications::Payloads.user(@user)
      )
      log_action('user_promoted_to_super_admin', { 
                   target_user_id: @user.id, 
                   target_user_email: @user.email 
                 })
      redirect_to internal_users_path, notice: "#{@user.full_name} has been promoted to super admin."
    rescue StandardError => e
      log_action('user_promotion_failed', { 
                   target_user_id: @user.id, 
                   error: e.message 
                 })
      redirect_to internal_users_path, alert: e.message
    end

    def demote_to_user
      ensure_super_admin
      return if performed?

      @user.demote_to_user!(demoted_by: current_user)
      Notifications::Dispatcher.publish(
        event_key: 'role_demoted_to_user',
        recipients: [@user],
        actor: current_user,
        context: Notifications::Payloads.user(@user)
      )
      log_action('user_demoted_to_user', { 
                   target_user_id: @user.id, 
                   target_user_email: @user.email 
                 })
      redirect_to internal_users_path, notice: "#{@user.full_name} has been demoted to user."
    rescue StandardError => e
      log_action('user_demotion_failed', { 
                   target_user_id: @user.id, 
                   error: e.message 
                 })
      redirect_to internal_users_path, alert: e.message
    end

    def demote_to_officer
      ensure_super_admin
      return if performed?

      @user.demote_to_officer!(demoted_by: current_user)
      Notifications::Dispatcher.publish(
        event_key: 'role_demoted_to_officer',
        recipients: [@user],
        actor: current_user,
        context: Notifications::Payloads.user(@user)
      )
      log_action('user_demoted_to_officer', { 
                   target_user_id: @user.id, 
                   target_user_email: @user.email 
                 })
      redirect_to internal_users_path, notice: "#{@user.full_name} has been demoted to officer."
    rescue StandardError => e
      log_action('user_demotion_failed', { 
                   target_user_id: @user.id, 
                   error: e.message 
                 })
      redirect_to internal_users_path, alert: e.message
    end

    def attendance_history
      # Users can view their own attendance history, admins can view any user's history
      unless @user == current_user || current_user.admin?
        redirect_to root_path, alert: 'You are not authorized to view this attendance history.'
        return
      end

      # Get all attendances for the user, ordered by event date (most recent first)
      @attendances = @user.attendances.includes(:event).joins(:event).order('events.date DESC')

      # Calculate attendance statistics
      present_count = @attendances.select { |a| a.status == 'present' }.count
      excused_count = @attendances.select { |a| a.status == 'excused' }.count
      absent_count = @attendances.select { |a| a.status == 'absent' }.count
      tardy_count = @attendances.select { |a| a.status == 'tardy' }.count
      total_count = @attendances.count
      
      # For attendance percentage and effective present count, tardies count as present
      present_with_tardy_count = present_count + tardy_count
      
      # Get demerit information
      demerit_count = @user.received_demerits.count
      # Calculate demerit points by summing up the absence_points of each demerit
      demerit_points = view_context.format_absence_points(@user.received_demerits.sum(&:absence_points))

      @attendance_stats = {
        present: present_count,
        excused: excused_count,
        absent: absent_count,
        tardy: tardy_count,
        total: total_count,
        present_percentage: total_count.positive? ? ((present_with_tardy_count.to_f / total_count) * 100).round(1) : 0,
        demerits: demerit_count,
        demerit_points: demerit_points
      }
    end

    def destroy
      ensure_super_admin
      return if performed?

      # Prevent users from deleting themselves
      if @user == current_user
        redirect_to internal_users_path, alert: 'You cannot delete your own account.'
        return
      end

      user_name = @user.full_name
      user_email = @user.email
      @user.destroy!
      log_action('user_deleted', { 
                   target_user_id: @user.id, 
                   target_user_name: user_name,
                   target_user_email: user_email 
                 })
      redirect_to internal_users_path, notice: "#{user_name} has been permanently deleted from the system."
    rescue StandardError => e
      log_action('user_deletion_failed', { 
                   target_user_id: @user.id, 
                   error: e.message 
                 })
      redirect_to internal_users_path, alert: "Failed to delete user: #{e.message}"
    end

    # SCRUM-120: View all absence points for all members
    def absence_report
      @users = User.where(role: 'user', approval_status: 'approved')
        .includes(:attendances, :received_demerits)
        .order(:full_name)
    end
  
    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      permitted_fields = [:full_name, :email_notifications_enabled]
      permitted_fields << :section_id if current_user.admin?

      params.require(:user).permit(*permitted_fields)
    end
  
    def ensure_admin
      return if current_user.admin?

      redirect_to root_path, alert: 'You must be an admin to access this page.'
    end

    def ensure_can_edit_user!
      return if current_user.admin? || current_user == @user

      redirect_to root_path, alert: 'You are not authorized to edit this member.'
    end

    def ensure_super_admin
      return if current_user.super_admin?

      redirect_to root_path, alert: 'You must be a super admin to perform this action.'
    end
  end
end
