# frozen_string_literal: true

class MembersController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_member

  def my_demerits
    @demerits = current_user.received_demerits.includes(:given_by).order(date: :desc)
    @total_absence_points = current_user.total_absence_points
  end

  private

  def ensure_member
    return if current_user.present?

    redirect_to root_path, alert: 'You must be logged in to view this page.'
  end
end