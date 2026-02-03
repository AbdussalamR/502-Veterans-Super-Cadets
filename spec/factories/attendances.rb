# frozen_string_literal: true

FactoryBot.define do
  factory :attendance do
    association :user
    association :event
    status { 'present' }

    trait :absent do
      status { 'absent' }
    end

    trait :excused do
      status { 'excused' }
    end
  end
end
