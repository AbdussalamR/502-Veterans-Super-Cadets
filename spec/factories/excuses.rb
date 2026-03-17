FactoryBot.define do
  factory :excuse do
    association :member, factory: :user
    reason { 'Valid reason for absence' }
    status { 'Pending Section Leader Review' }
    submission_date { Time.current }
    proof_link { 'https://example.com/proof' }

    # Handle the event association properly for many-to-many
    after(:build) do |excuse|
      excuse.events << build(:event) if excuse.events.empty? && !excuse.recurring?
    end

    trait :approved do
      status { 'approved' }
      reviewed_date { Time.current }
      after(:create) { |e| e.add_reviewer(create(:user, :officer)) }
    end

    trait :recurring do
      recurring { true }
      recurring_days { '1,3' }
      start_date { 1.week.from_now.beginning_of_day }
      end_date { 5.weeks.from_now.end_of_day }
      recurring_start_time { Time.zone.parse('08:00') }
      recurring_end_time { Time.zone.parse('23:59') }
    end
  end
end