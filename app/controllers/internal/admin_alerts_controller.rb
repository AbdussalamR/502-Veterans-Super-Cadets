# frozen_string_literal: true

module Internal
  class AdminAlertsController < ApplicationController
    before_action :require_super_admin!

    def dismiss
      alert = current_user.admin_alerts.find(params[:id])
      alert.mark_read!
      redirect_back(fallback_location: internal_events_path)
    end

    private

    def require_super_admin!
      redirect_to internal_events_path, alert: 'Not authorized.' unless current_user&.super_admin?
    end
  end
end
