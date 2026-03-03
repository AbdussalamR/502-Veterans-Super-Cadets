# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Public::Pages', type: :request do
  describe 'Root path' do
    it 'redirects to /public/home' do
      get '/'
      expect(response).to redirect_to('/public/home')
    end
  end

  describe 'GET /public/home' do
    it 'renders successfully without authentication' do
      get public_home_path
      expect(response).to have_http_status(:success)
    end

    it 'uses the public layout' do
      get public_home_path
      expect(response.body).not_to include('Sign Out') # The public layout shouldn't show internal nav
    end
  end

  describe 'GET /public/performance_request' do
    it 'renders successfully without authentication' do
      get public_performance_request_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /public/media_gallery' do
    it 'renders successfully without authentication' do
      get public_media_gallery_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /public/audition_information' do
    it 'renders successfully without authentication' do
      get public_audition_information_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET /public/contact' do
    it 'renders successfully without authentication' do
      get public_contact_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'accessibility (all public pages accessible without login)' do
    it 'does not redirect any public page to sign-in' do
      [public_home_path, public_performance_request_path, public_media_gallery_path,
       public_audition_information_path, public_contact_path,].each do |path|
        get path
        expect(response).not_to redirect_to('/users/sign_in'), "Expected #{path} to not redirect to sign-in"
      end
    end
  end
end
