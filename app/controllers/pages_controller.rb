# frozen_string_literal: true

class PagesController < ApplicationController
  skip_before_action :authenticate_user!

  def home
  end

  def performance_request
  end

  def media_gallery
  end

  def audition_information
  end

  def contact
  end
end
