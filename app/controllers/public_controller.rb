# frozen_string_literal: true

class PublicController < ApplicationController
  # Skip authentication for public-facing pages
  skip_before_action :authenticate_user!
  
  # Use the public layout with maroon styling
  layout 'public'
end
