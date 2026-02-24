require 'rails_helper'

RSpec.describe "Event Feeds", type: :request do
  let!(:user) { FactoryBot.create(:user, calendar_token: "secure_token_123") }
  let!(:future_event) do
    FactoryBot.create(:event, title: "Choir Practice", date: 1.day.from_now, end_time: 1.day.from_now + 2.hours)
  end

  describe "ICS Feed Access" do
    it "blocks access without a token (Integrity Check)" do
      get events_path(format: :ics)
      expect(response).to redirect_to('/users/sign_in')
    end

    it "allows access with a valid user token (Bypass Check)" do
      get events_path(format: :ics, token: user.calendar_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("BEGIN:VCALENDAR")
      expect(response.body).to include("Choir Practice")
    end

    it "blocks access with an incorrect token (Rainy Day)" do
      get events_path(format: :ics, token: "wrong_token")
      expect(response).to redirect_to('/users/sign_in')
    end
  end

  describe "RSS Feed Access" do
    it "renders valid XML with the correct token" do
      get events_path(format: :rss, token: user.calendar_token)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/rss+xml")
      expect(response.body).to include("Choir Practice")
    end
  end
end