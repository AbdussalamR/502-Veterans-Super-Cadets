FactoryBot.define do
  factory :excuse do
    association :member, factory: :user
    reason { 'Valid reason for absence' }
    status { 'Pending Officer Review' }
    submission_date { Time.current }
    proof_link { 'https://example.com/proof' }

    # Set manual_event_ids so the must_have_events validation passes (mirrors the form flow)
    after(:build) do |excuse|
      excuse.manual_event_ids = [create(:event).id] if !excuse.recurring? && excuse.events.empty? && excuse.manual_event_ids.blank?
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