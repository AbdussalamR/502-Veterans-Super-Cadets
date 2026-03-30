# frozen_string_literal: true

FactoryBot.define do
  factory :performance_request do
    sequence(:name)          { |n| "Requester #{n}" }
    sequence(:organization)  { |n| "Organization #{n}" }
    sequence(:contact_email) { |n| "requester#{n}@example.com" }
    location                 { "Kyle Field, College Station, TX" }
    event_date               { 4.weeks.from_now.to_date }
    notes                    { nil }
    status                   { 'pending' }

    trait :reviewed do
      status { 'reviewed' }
    end

    trait :with_notes do
      notes { "Please arrive 30 minutes early." }
    end
  end
end
