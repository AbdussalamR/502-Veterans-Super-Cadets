FactoryBot.define do
  factory :contact_message do
    name    { 'John Doe' }
    email   { 'john@example.com' }
    message { 'This is a test message.' }
    read_at { nil }

    trait :read do
      read_at { 1.hour.ago }
    end
  end
end
