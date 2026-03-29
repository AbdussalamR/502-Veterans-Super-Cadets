# app/controllers/admin/audition_sessions_controller.rb
class Admin::AuditionSessionsController < InternalController
  before_action :require_admin
  before_action :set_audition_session, only: %i[edit update destroy]

  def index
    @audition_sessions = AuditionSession.chronological
  end

  def new
    @audition_session = AuditionSession.new
  end

  def edit; end

  def create
    @audition_session = AuditionSession.new(audition_session_params)
    if @audition_session.save
      redirect_to admin_website_path(tab: 'auditions'), notice: "Audition session added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @audition_session.update(audition_session_params)
      redirect_to admin_website_path(tab: 'auditions'), notice: "Audition session updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @audition_session.destroy
    redirect_to admin_website_path(tab: 'auditions'), notice: "Audition session removed."
  end

  private

  def set_audition_session
    @audition_session = AuditionSession.find(params[:id])
  end

  def audition_session_params
    params.require(:audition_session).permit(:label, :start_datetime, :end_datetime, :location)
  end
end