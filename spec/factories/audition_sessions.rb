FactoryBot.define do
  factory :audition_session do
    label { "imaginary audition" }
    start_datetime { 1.week.from_now }
    end_datetime { 1.week.from_now + 3.hours }
    location { "imaginary location" }
  end
end
