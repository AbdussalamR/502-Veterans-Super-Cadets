# frozen_string_literal: true

class InternalController < ApplicationController
  # Require authentication for all internal pages by default
  before_action :authenticate_user!
  
  # Use the internal layout with the member navigation bar
  layout 'internal'

  private 

  def require_admin
    return if current_user&.admin?

    flash[:alert] = 'You are not authorized to view this page.'
    redirect_to root_path
  end
end
