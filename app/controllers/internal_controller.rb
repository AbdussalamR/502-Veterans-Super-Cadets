# frozen_string_literal: true

class InternalController < ApplicationController
  # Require authentication for all internal pages by default
  before_action :authenticate_user!
  
  # Use the internal layout with the member navigation bar
  layout 'internal'
end
