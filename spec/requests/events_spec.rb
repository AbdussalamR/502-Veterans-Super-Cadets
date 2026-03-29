# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Events', type: :request do
  let(:user) { create(:user) }
  let(:admin_user) { create(:user, :officer) }

  let(:valid_attributes) do
    {
      title: 'Test Event',
      date: 1.week.from_now,
      end_time: 1.week.from_now + 2.hours,
      location: 'Test Location',
      description: 'Test description',
    }
  end

  let(:invalid_attributes) do
    {
      title: '',
      date: nil,
    }
  end

  before do
    sign_in user
  end

  describe 'GET /index' do
    it 'renders a successful response' do
      Event.create! valid_attributes
      get internal_events_url
      expect(response).to be_successful
    end

    it 'separates upcoming and past events' do
      Event.create! valid_attributes
      Event.create! valid_attributes.merge(title: 'Past Event', date: 1.week.ago, end_time: 1.week.ago + 2.hours)
      get internal_events_url
      expect(response).to be_successful
      expect(response.body).to include('Test Event')
      expect(response.body).to include('Past Event')
    end
  end

  describe 'GET /show' do
    it 'renders a successful response' do
      event = Event.create! valid_attributes
      get internal_event_url(event)
      expect(response).to be_successful
    end

    # it 'returns 404 for non-existent event' do
    #   expect do
    #     get internal_event_url(id: 99_999)
    #   end.to raise_error(ActiveRecord::RecordNotFound)
    # end

    it 'returns 404 for non-existent event' do
      sign_in user  
      # or create(:user)
      get internal_event_path(99_999)
      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /new' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'renders a successful response' do
        get new_internal_event_url
        expect(response).to be_successful
      end
    end

    context 'as regular user' do
      it 'denies access' do
        get new_internal_event_url
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /edit' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'renders a successful response' do
        event = Event.create! valid_attributes
        get edit_internal_event_url(event)
        expect(response).to be_successful
      end
    end

    context 'as regular user' do
      it 'denies access' do
        event = Event.create! valid_attributes
        get edit_internal_event_url(event)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /create' do
    context 'as admin user' do
      before { sign_in admin_user }

      context 'with valid parameters' do
        it 'creates a new Event' do
          expect do
            post internal_events_url, params: { event: valid_attributes }
          end.to change(Event, :count).by(1)
        end

        it 'enqueues notifications for approved members' do
          create(:user)

          expect do
            post internal_events_url, params: { event: valid_attributes }
          end.to have_enqueued_job(Notifications::DeliverNotificationJob).exactly(3).times
        end

        it 'redirects to the created event' do
          post internal_events_url, params: { event: valid_attributes }
          expect(response).to redirect_to(internal_event_url(Event.last))
        end
      end

      context 'with invalid parameters' do
        it 'does not create a new Event' do
          expect do
            post internal_events_url, params: { event: invalid_attributes }
          end.to change(Event, :count).by(0)
        end

        it "renders a response with 422 status (i.e. to display the 'new' template)" do
          post internal_events_url, params: { event: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with missing required fields' do
        it 'rejects event without a title' do
          post internal_events_url, params: { event: valid_attributes.merge(title: '') }
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'rejects event without a date' do
          post internal_events_url, params: { event: valid_attributes.merge(date: nil) }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'as regular user' do
      it 'denies access' do
        post internal_events_url, params: { event: valid_attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'as unauthenticated user' do
      before { sign_out }

      it 'redirects to sign in' do
        post internal_events_url, params: { event: valid_attributes }
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'PATCH /update' do
    context 'as admin user' do
      let(:new_attributes) do
        {
          title: 'Updated Event Title',
          location: 'Updated Location',
        }
      end

      before { sign_in admin_user }

      context 'with valid parameters' do
        it 'updates the requested event' do
          event = Event.create! valid_attributes
          patch internal_event_url(event), params: { event: new_attributes }
          event.reload
          expect(event.title).to eq('Updated Event Title')
          expect(event.location).to eq('Updated Location')
        end

        it 'redirects to the event' do
          event = Event.create! valid_attributes
          patch internal_event_url(event), params: { event: new_attributes }
          event.reload
          expect(response).to redirect_to(internal_event_url(event))
        end

        it 'enqueues notifications when updating an event' do
          create(:user)
          event = Event.create! valid_attributes

          expect do
            patch internal_event_url(event), params: { event: new_attributes }
          end.to have_enqueued_job(Notifications::DeliverNotificationJob).exactly(3).times
        end
      end

      context 'with invalid parameters' do
        it "renders a response with 422 status (i.e. to display the 'edit' template)" do
          event = Event.create! valid_attributes
          patch internal_event_url(event), params: { event: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'as regular user' do
      it 'denies access' do
        event = Event.create! valid_attributes
        patch internal_event_url(event), params: { event: { title: 'Updated Title' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /destroy' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'destroys the requested event' do
        event = Event.create! valid_attributes
        expect do
          delete internal_event_url(event)
        end.to change(Event, :count).by(-1)
      end

      it 'redirects to the events list' do
        event = Event.create! valid_attributes
        delete internal_event_url(event)
        expect(response).to redirect_to(internal_events_url)
      end

      it 'enqueues notifications when canceling an event' do
        create(:user)
        event = Event.create! valid_attributes

        expect do
          delete internal_event_url(event)
        end.to have_enqueued_job(Notifications::DeliverNotificationJob).exactly(3).times
      end
    end

    context 'as regular user' do
      it 'denies access' do
        event = Event.create! valid_attributes
        delete internal_event_url(event)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'Approved excuses display' do
    let(:event) { Event.create! valid_attributes }
    let(:excused_user1) { create(:user, approval_status: 'approved') }
    let(:excused_user2) { create(:user, approval_status: 'approved') }

    before do
      Excuse.create!(member: excused_user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      Excuse.create!(member: excused_user2, event: event, reason: 'Doctor', status: 'approved', proof_link: 'https://example.com/proof2')
    end

    context 'as admin user' do
      before { sign_in admin_user }

      describe 'GET /show' do
        it 'displays approved excuses count and names' do
          get internal_event_url(event)
          expect(response).to be_successful
          expect(response.body).to include('Approved Excuses')
          expect(response.body).to include(excused_user1.full_name)
          expect(response.body).to include(excused_user2.full_name)
        end
      end

      describe 'GET /index' do
        it 'displays approved excuses count in event cards' do
          get internal_events_url
          expect(response).to be_successful
          expect(response.body).to include('excuse')
        end
      end
    end

    context 'as regular user' do
      describe 'GET /show' do
        it 'does not display approved excuses section' do
          get internal_event_url(event)
          expect(response).to be_successful
          expect(response.body).not_to include('Approved Excuses')
        end
      end
    end
  end

  describe 'JSON requests' do
    let(:event) { Event.create! valid_attributes }

    before { sign_in admin_user }

    describe 'GET /show' do
      it 'returns JSON format' do
        get internal_event_url(event, format: :json)
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
      end
    end

    describe 'POST /create' do
      it 'returns JSON format on success' do
        post internal_events_url(format: :json), params: { event: valid_attributes }
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
      end
    end

    describe 'PATCH /update' do
      it 'returns JSON format on success' do
        patch internal_event_url(event, format: :json), params: { event: { title: 'Updated' } }
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')
      end

      it 'returns JSON format on error' do
        patch internal_event_url(event, format: :json), params: { event: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.content_type).to include('application/json')
      end
    end

    describe 'DELETE /destroy' do
      it 'returns no content' do
        delete internal_event_url(event, format: :json)
        expect(response).to have_http_status(:no_content)
      end
    end
  end
end
