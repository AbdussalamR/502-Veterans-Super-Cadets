# spec/requests/public_calendar_spec.rb
require 'rails_helper'

RSpec.describe "Public Calendar Endpoints", type: :request do
  describe "GET /public/calendar" do
    it "renders the calendar HTML page successfully" do
      get "/public/calendar"
      
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Performance Schedule")
      expect(response.body).to include('id="public-calendar"') 
    end
  end

  describe "GET /public/calendar.json" do
    # We use let! to ensure these are created before the 'get' happens
    let!(:public_event) do
      Event.create!(
        title: "Spring Showcase",
        date: Time.current + 2.days,
        end_time: Time.current + 2.days + 2.hours, # Added end_time
        location: "Zach 582",
        description: "A wonderful public performance.",
        is_public: true,
        ticket_url: "https://example.com/tickets"
      )
    end

    let!(:private_event) do
      Event.create!(
        title: "Secret Rehearsal",
        date: Time.current + 3.days,
        end_time: Time.current + 3.days + 1.hour, # Added end_time
        location: "Choir Room",
        is_public: false
      )
    end

    it "returns successful JSON response" do
      get "/public/calendar.json"
      
      expect(response).to have_http_status(:success)
      expect(response.content_type).to match(%r{application/json})
    end

    it "includes public event data in the JSON response" do
      get "/public/calendar.json"
      json_response = JSON.parse(response.body)
      
      response_string = json_response.to_s
      expect(response_string).to include("Spring Showcase")
      expect(response_string).to include("Zach 582")
    end
  end
end