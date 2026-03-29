# frozen_string_literal: true

module Admin
  class RegistrationsController < InternalController
    include Loggable
    
    before_action :authenticate_user!
    before_action :require_admin

    def index
      # Handle search functionality
      if params[:search].present?
        search_term = params[:search].strip
        search_condition = 'LOWER(full_name) LIKE ? OR LOWER(email) LIKE ?'
        search_params = ["%#{search_term.downcase}%", "%#{search_term.downcase}%"]

        @pending_users = User.pending.where(search_condition, *search_params).order(created_at: :desc)
        @approved_users = User.approved.where(search_condition, *search_params).order(created_at: :desc)
        @rejected_users = User.rejected.where(search_condition, *search_params).order(created_at: :desc)
      else
        @pending_users = User.pending.order(created_at: :desc)
        @approved_users = User.approved.order(created_at: :desc)
        @rejected_users = User.rejected.order(created_at: :desc)
      end

      # Store search parameter for form persistence
      @search_term = params[:search]
    end

    def approve
      @user = User.find(params[:id])

      begin
        @user.approve!(approved_by: current_user)
        Notifications::Dispatcher.publish(
          event_key: 'registration_approved',
          recipients: [@user],
          actor: current_user,
          context: Notifications::Payloads.user(@user)
        )
        log_action('user_registration_approved', { 
          target_user_id: @user.id, 
          target_user_email: @user.email 
        })
        flash[:notice] = "User #{@user.full_name} has been approved"
      rescue StandardError => e
        log_action('user_approval_failed', { 
          target_user_id: @user.id, 
          error: e.message 
        })
        flash[:alert] = e.message
      end

      redirect_to admin_registrations_path
    end

    def reject
      @user = User.find(params[:id])

      begin
        @user.reject!(rejected_by: current_user)
        Notifications::Dispatcher.publish(
          event_key: 'registration_rejected',
          recipients: [@user],
          actor: current_user,
          context: Notifications::Payloads.user(@user)
        )
        log_action('user_registration_rejected', { 
          target_user_id: @user.id, 
          target_user_email: @user.email 
        })
        flash[:notice] = "User #{@user.full_name} has been rejected"
      rescue StandardError => e
        log_action('user_rejection_failed', { 
          target_user_id: @user.id, 
          error: e.message 
        })
        flash[:alert] = e.message
      end

      redirect_to admin_registrations_path
    end

    def destroy_rejected
      @user = User.find(params[:id])

      # Only allow deletion of rejected users
      unless @user.rejected?
        flash[:alert] = 'Only rejected users can be permanently deleted'
        redirect_to admin_registrations_path
        return
      end

      begin
        user_name = @user.full_name
        user_email = @user.email
        user_id = @user.id
        @user.destroy!
        log_action('rejected_user_deleted', { 
          target_user_id: user_id, 
          target_user_name: user_name,
          target_user_email: user_email 
        })
        flash[:notice] = "Rejected user #{user_name} has been permanently deleted from the system"
      rescue StandardError => e
        log_action('rejected_user_deletion_failed', { 
          target_user_id: @user.id, 
          error: e.message 
        })
        flash[:alert] = "Failed to delete user: #{e.message}"
      end

      redirect_to admin_registrations_path
    end

    private

    def require_admin
      return if current_user&.admin?

      flash[:alert] = 'You are not authorized to access this page'
      redirect_to root_path
    end
  end
end
