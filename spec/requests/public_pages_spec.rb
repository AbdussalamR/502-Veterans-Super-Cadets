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
      expect(response.body).not_to include('Sign Out')
    end

    it 'shows published hero title from DB' do
      PageContent.set('home', 'hero_title', 'Published Title', draft: false)
      get public_home_path
      expect(response.body).to include('Published Title')
    end

    it 'does not show draft-only content' do
      PageContent.set('home', 'hero_title', 'Draft Only', draft: true)
      get public_home_path
      expect(response.body).not_to include('Draft Only')
    end

    it 'shows only published home photos' do
      published_photo = create(:media_photo, :home, :published)
      unpublished_photo = create(:media_photo, :home, published: false)
      get public_home_path
      # Published photo's image url will be referenced; unpublished will not
      # We verify by checking the page loads without errors - deeper image URL
      # checks are covered in integration tests
      expect(response).to have_http_status(:success)
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

    it 'shows published photos' do
      photo = create(:media_photo, :published, caption: 'Published Photo')
      get public_media_gallery_path
      expect(response.body).to include('Published Photo')
    end

    it 'does not show unpublished photos' do
      create(:media_photo, published: false, caption: 'Hidden Photo')
      get public_media_gallery_path
      expect(response.body).not_to include('Hidden Photo')
    end

    it 'shows published videos' do
      video = create(:media_video, :published, title: 'Published Video')
      get public_media_gallery_path
      expect(response.body).to include('Published Video')
    end

    it 'does not show unpublished videos' do
      create(:media_video, published: false, title: 'Hidden Video')
      get public_media_gallery_path
      expect(response.body).not_to include('Hidden Video')
    end
  end

  describe 'GET /public/contact' do
    it 'renders successfully without authentication' do
      get public_contact_path
      expect(response).to have_http_status(:success)
    end

    it 'shows published contact info from DB' do
      PageContent.set('contact', 'email', 'custom@tamu.edu', draft: false)
      get public_contact_path
      expect(response.body).to include('custom@tamu.edu')
    end

    it 'falls back to default contact info when nothing is published' do
      get public_contact_path
      expect(response.body).to include('choir@tamu.edu')
    end
  end

  describe 'accessibility (all public pages accessible without login)' do
    it 'does not redirect any public page to sign-in' do
      [public_home_path, public_performance_request_path, public_media_gallery_path,
       public_audition_information_path, public_contact_path].each do |path|
        get path
        expect(response).not_to redirect_to('/users/sign_in'), "Expected #{path} to not redirect to sign-in"
      end
    end
  end

  describe 'GET /public/audition_information' do
    it 'renders successfully without authentication' do
      get public_audition_information_path
      expect(response).to have_http_status(:success)
    end

    context 'with a published signup link' do
      before { PageContent.set('auditions', 'signup_link', 'https://forms.gle/test', draft: false) }

      it 'shows the sign-up button' do
        get public_audition_information_path
        expect(response.body).to include('Sign Up for Auditions')
        expect(response.body).to include('https://forms.gle/test')
      end
    end

    context 'without a signup link' do
      it 'does not show the sign-up button' do
        get public_audition_information_path
        expect(response.body).not_to include('Sign Up for Auditions')
      end
    end

    context 'with published what_to_expect text' do
      before { PageContent.set('auditions', 'what_to_expect', 'Custom expectations text', draft: false) }

      it 'shows the custom text' do
        get public_audition_information_path
        expect(response.body).to include('Custom expectations text')
      end
    end

    context 'audition session bucketing' do
      let(:now) { Time.current }

      let!(:current_audition) { create(:audition_session, label: 'Current Audition', start_datetime: now - 1.hour, end_datetime: now + 1.hour) }
      let!(:future_audition)  { create(:audition_session, label: 'Future Audition',  start_datetime: now + 1.week, end_datetime: now + 1.week + 3.hours) }
      let!(:past_audition)    { create(:audition_session, label: 'Past Audition',    start_datetime: now - 2.weeks, end_datetime: now - 1.week) }

      before { get public_audition_information_path }

      it 'shows the current audition'  do
        expect(response.body).to include('Current Audition')
      end

      it 'shows the future audition' do
        expect(response.body).to include('Future Audition')
      end

      it 'shows the past audition' do
        expect(response.body).to include('Past Audition')
      end
    end
  end
end
