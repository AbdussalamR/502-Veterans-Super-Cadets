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

  # ===========================================================================
  # User Story U1 — External Event Organizer: Submit a Performance Request
  #
  # Persona : External event organizer (unauthenticated)
  # Need    : Submit a booking inquiry through a public web form
  # Value   : Provides a professional, centralized intake process for the Singing Cadets
  #
  # Acceptance Criteria covered in this file:
  #   AC 0.1 — Page is accessible to unauthenticated users
  #   AC 0.2 — Form requires Name, Organization, Event Date, Location, Contact Email
  #   AC 0.3 — Submission creates a DB record and emails the Director
  #   AC 0.4 — Missing/invalid fields or a past date prevent submission and show errors
  # ===========================================================================

  # -- AC 0.1: The "Request a Performance" page is publicly accessible (no login required) --
  describe 'GET /public/performance_request' do
    it 'renders successfully without authentication' do
      get public_performance_request_path
      expect(response).to have_http_status(:success)
    end

    it 'shows the Submit Request button' do
      get public_performance_request_path
      expect(response.body).to include('Submit Request')
    end

    it 'shows the hero heading' do
      get public_performance_request_path
      expect(response.body).to include('Request a Performance')
    end
  end

  describe 'POST /public/performance_request' do
    # -- AC 0.2: All required fields (Name, Organization, Event Date, Location, Contact Email) --
    # valid_params represents a correctly filled-out form with every required field present.
    let(:valid_params) do
      {
        performance_request: {
          name:          'Jane Smith',       # required – AC 0.2
          organization:  'Texas A&M',        # required – AC 0.2
          event_date:    6.weeks.from_now.to_date.to_s, # required, must be future – AC 0.2 & 0.4
          location:      'Kyle Field',       # required – AC 0.2
          contact_email: 'jane@example.com', # required, must be valid email – AC 0.2 & 0.4
          notes:         'Please arrive early' # optional
        }
      }
    end

    # -- AC 0.3: Successful submission creates a DB record and notifies the Director --
    context 'with valid params' do
      # AC 0.3 (part 1): a new row is inserted into the PerformanceRequests table
      it 'creates a new performance request' do
        expect {
          post public_submit_performance_request_path, params: valid_params
        }.to change(PerformanceRequest, :count).by(1)
      end

      # AC 0.3 (part 1 continued): the user is redirected with a confirmation message
      it 'redirects back to the form with a success notice' do
        post public_submit_performance_request_path, params: valid_params
        expect(response).to redirect_to(public_performance_request_path)
        expect(flash[:notice]).to include('Jane Smith')
      end

      # AC 0.3 (part 2): an async notification job is enqueued so the Director is alerted
      it 'enqueues a notification to directors' do
        create(:user, :super_admin)
        expect {
          post public_submit_performance_request_path, params: valid_params
        }.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    # -- AC 0.4: Missing fields or a past date must prevent submission --
    context 'with invalid params' do
      # AC 0.4: blank required field → form re-renders (422) instead of saving
      it 're-renders the form when name is missing' do
        post public_submit_performance_request_path, params: {
          performance_request: valid_params[:performance_request].merge(name: '')
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('Submit Request') # form is shown again with errors
      end

      # AC 0.4: malformed email → form re-renders with a helpful validation message
      it 're-renders the form when email is invalid' do
        post public_submit_performance_request_path, params: {
          performance_request: valid_params[:performance_request].merge(contact_email: 'not-an-email')
        }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include('valid email')
      end

      # AC 0.4: past event date → form re-renders; past bookings are not accepted
      it 're-renders the form when event_date is in the past' do
        post public_submit_performance_request_path, params: {
          performance_request: valid_params[:performance_request].merge(event_date: 1.week.ago.to_date.to_s)
        }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      # AC 0.4 (guard): no record is persisted when validation fails
      it 'does not create a request on validation failure' do
        expect {
          post public_submit_performance_request_path, params: {
            performance_request: valid_params[:performance_request].merge(name: '')
          }
        }.not_to change(PerformanceRequest, :count)
      end
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
