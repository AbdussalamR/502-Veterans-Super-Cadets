# frozen_string_literal: true

FactoryBot.define do
  factory :excuse do
    association :member, factory: :user
    association :event
    association :reviewed_by, factory: :user, optional: true
    reason { 'Valid reason for absence' }
    status { 'pending' }
    submission_date { Time.current }
    proof_link { 'https://example.com/proof' }

    trait :approved do
      status { 'approved' }
      reviewed_date { Time.current }
      association :reviewed_by, factory: :user
    end

    trait :denied do
      status { 'denied' }
      reviewed_date { Time.current }
      association :reviewed_by, factory: :user
    end

    trait :pending do
      status { 'pending' }
    end
  end
end

