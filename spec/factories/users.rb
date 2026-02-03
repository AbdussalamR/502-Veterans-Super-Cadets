# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    sequence(:full_name) { |n| "User #{n}" }
    sequence(:uid) { |n| "uid#{n}" }
    provider { 'google_oauth2' }
    role { 'user' }
    approval_status { 'approved' }

    trait :officer do
      role { 'officer' }
    end

    trait :super_admin do
      role { 'super_admin' }
    end

    trait :pending do
      approval_status { 'pending' }
    end

    trait :rejected do
      approval_status { 'rejected' }
    end
  end
end
