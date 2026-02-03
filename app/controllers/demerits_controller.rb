# frozen_string_literal: true

class DemeritsController < ApplicationController
  include Loggable
  
  before_action :authenticate_user!
  before_action :ensure_admin_or_officer, except: [:show]
  before_action :set_demerit, only: [:show, :edit, :update, :destroy]
  before_action :set_member, only: [:new, :create]
  before_action :ensure_authorized_for_demerit, only: [:show]

  # SCRUM-114: View all demerits
  def index
    @demerits = Demerit.includes(:member, :given_by).order(date: :desc)
    # Note: In a real implementation, we would add pagination here
    # @demerits = @demerits.paginate(page: params[:page], per_page: 15)
  end

  # Show a specific demerit
  def show
  end

  # SCRUM-107: Form for creating a new demerit
  def new
    @demerit = Demerit.new(member: @member, date: Time.current)
  end

  # SCRUM-108: Create a new demerit
  def create
    @demerit = Demerit.new(demerit_params)
    @demerit.given_by = current_user
    
    if @demerit.save
      log_create_success(@demerit, { 
        member_id: @demerit.member_id, 
        member_name: @demerit.member.full_name,
        value: @demerit.value 
      })
      flash[:success] = "Discipline points were successfully assigned to #{@demerit.member.full_name}."
      redirect_to @demerit.member
    else
      log_create_failure(@demerit)
      flash.now[:error] = "Error creating discipline record: #{@demerit.errors.full_messages.join(', ')}"
      render :new
    end
  end

  # Edit a demerit
  def edit
  end

  # Update a demerit
  def update
    member = @demerit.member
    if @demerit.update(demerit_params)
      log_update_success(@demerit, { 
        member_id: member.id, 
        member_name: member.full_name 
      })
      flash[:success] = 'Discipline record was successfully updated.'
      redirect_to user_path(member)
    else
      log_update_failure(@demerit)
      flash.now[:error] = "Error updating discipline record: #{@demerit.errors.full_messages.join(', ')}"
      render :edit
    end
  end

  # Delete a demerit
  def destroy
    member = @demerit.member
    demerit_value = @demerit.value
    @demerit.destroy
    log_destroy_success(@demerit, { 
      member_id: member.id, 
      member_name: member.full_name,
      value: demerit_value 
    })
    flash[:success] = 'Discipline record was successfully deleted.'
    
    # Redirect based on source parameter
    if params[:source] == 'demerits_index'
      redirect_to demerits_path
    else
      redirect_to user_path(member)
    end
  end

  private

  def set_demerit
    @demerit = Demerit.find(params[:id])
  end

  def set_member
    @member = User.find(params[:member_id]) if params[:member_id]
  end
  
  def ensure_authorized_for_demerit
    # Allow users to view their own demerits or admins/officers to view any demerit
    unless @demerit.member == current_user || current_user.admin? || current_user.officer?
      log_authorization_failure('view_demerit', { demerit_id: @demerit.id })
      redirect_to root_path, alert: "You are not authorized to view this demerit."
    end
  end

  def ensure_admin_or_officer
    return if current_user.admin? || current_user.officer?

    log_authorization_failure('admin_or_officer_required', { action: action_name })
    redirect_to root_path, alert: 'You must be an admin or officer to access this page.'
  end

  def demerit_params
    params.require(:demerit).permit(:member_id, :value, :reason, :date)
  end
end