require 'rails_helper'

RSpec.describe 'Internal::Event Feeds', type: :request do
  let!(:user) { FactoryBot.create(:user, calendar_token: 'secure_token_123') }
  let!(:future_event) do
    FactoryBot.create(:event, title: 'Choir Practice', date: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
  end

  describe 'ICS Feed Access' do
    it 'blocks access without a token (Integrity Check)' do
      get internal_events_path(format: :ics)
      expect(response).to redirect_to('/users/sign_in')
    end

    it 'allows access with a valid user token (Bypass Check)' do
      get internal_events_path(format: :ics, token: user.calendar_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('BEGIN:VCALENDAR')
      expect(response.body).to include('Choir Practice')
    end

    it 'blocks access with an incorrect token (Rainy Day)' do
      get internal_events_path(format: :ics, token: 'wrong_token')
      expect(response).to redirect_to('/users/sign_in')
    end

    it 'blocks access with an empty token' do
      get internal_events_path(format: :ics, token: '')
      expect(response).to redirect_to('/users/sign_in')
    end

    it 'allows access for a signed-in user without a token' do
      sign_in user
      get internal_events_path(format: :ics)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('BEGIN:VCALENDAR')
    end

    it 'returns correct content-type for calendar apps' do
      get internal_events_path(format: :ics, token: user.calendar_token)
      expect(response.content_type).to include('text/calendar')
    end

    it 'includes required iCalendar structure' do
      get internal_events_path(format: :ics, token: user.calendar_token)
      expect(response.body).to include('BEGIN:VCALENDAR')
      expect(response.body).to include('END:VCALENDAR')
      expect(response.body).to include('BEGIN:VEVENT')
      expect(response.body).to include('END:VEVENT')
    end

    it 'includes the event title and uid in the feed' do
      get internal_events_path(format: :ics, token: user.calendar_token)
      expect(response.body).to include('Choir Practice')
      expect(response.body).to include("event-#{future_event.id}@singing-cadets-tamu")
    end
  end

  describe 'RSS Feed Access' do
    it 'renders valid XML with the correct token' do
      get internal_events_path(format: :rss, token: user.calendar_token)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/rss+xml')
      expect(response.body).to include('Choir Practice')
    end

    it 'blocks RSS access without a token' do
      get internal_events_path(format: :rss)
      expect(response).to redirect_to('/users/sign_in')
    end

    it 'returns well-formed RSS XML' do
      get internal_events_path(format: :rss, token: user.calendar_token)
      expect(response.body).to include('<rss version="2.0">')
      expect(response.body).to include('<channel>')
      expect(response.body).to include('<item>')
    end

    it 'only includes upcoming events in the RSS feed' do
      past_event = FactoryBot.create(:event, title: 'Old Concert', date: 1.day.ago, end_time: 1.day.ago + 2.hours)
      get internal_events_path(format: :rss, token: user.calendar_token)
      expect(response.body).to include('Choir Practice')
      expect(response.body).not_to include(past_event.title)
    end
  end
end