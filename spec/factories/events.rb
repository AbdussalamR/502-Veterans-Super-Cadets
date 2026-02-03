# frozen_string_literal: true

FactoryBot.define do
  factory :event do
    sequence(:title) { |n| "Event #{n}" }
    date { 1.week.from_now }
    end_time { date + 2.hours }
    location { 'Test Location' }
    description { 'Test event description' }
    allow_self_checkin { false }

    trait :past do
      date { 1.week.ago }
      end_time { date + 2.hours }
    end

    trait :today do
      date { Time.zone.today }
      end_time { date + 2.hours }
    end

    trait :with_self_checkin do
      allow_self_checkin { true }
      checkin_passcode { '1234' }
    end

    trait :self_checkin_available do
      allow_self_checkin { true }
      checkin_passcode { '1234' }
      date { 5.minutes.from_now }
      end_time { 1.hour.from_now }
    end

    trait :self_checkin_before_window do
      allow_self_checkin { true }
      checkin_passcode { '1234' }
      date { 2.hours.from_now }
      end_time { 3.hours.from_now }
    end

    trait :self_checkin_after_window do
      allow_self_checkin { true }
      checkin_passcode { '1234' }
      date { 2.hours.ago }
      end_time { 30.minutes.ago }
    end
  end
end
