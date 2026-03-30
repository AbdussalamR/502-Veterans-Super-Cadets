# frozen_string_literal: true

module Internal
  class PerformanceRequestsController < InternalController
    before_action :require_super_admin!
    before_action :set_performance_request, only: [:show, :update]

    def index
      @performance_requests = PerformanceRequest.newest
    end

    def show; end

    def update
      new_status = params[:status]
      unless %w[reviewed pending].include?(new_status)
        return redirect_to internal_performance_request_path(@performance_request), alert: "Invalid status."
      end

      @performance_request.update!(status: new_status)
      label = new_status == 'reviewed' ? 'approved' : 'reset to pending'
      redirect_to internal_performance_requests_path, notice: "Performance request from #{@performance_request.name} has been #{label}."
    end

    private

    def require_super_admin!
      return if current_user.super_admin?

      redirect_to internal_events_path, alert: "Access denied. Directors only."
    end

    def set_performance_request
      @performance_request = PerformanceRequest.find(params[:id])
    end
  end
end
