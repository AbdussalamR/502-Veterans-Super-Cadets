# frozen_string_literal: true

FactoryBot.define do
  factory :demerit do
    association :member, factory: :user
    association :given_by, factory: :user
    value { 1 }
    date { Time.current }
    reason { 'Test demerit reason' }
  end
end
