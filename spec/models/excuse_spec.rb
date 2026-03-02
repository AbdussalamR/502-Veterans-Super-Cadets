# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Excuse, type: :model do
  describe 'associations' do
    it 'belongs to member (User)' do
      excuse = Excuse.reflect_on_association(:member)
      expect(excuse.macro).to eq(:belongs_to)
      expect(excuse.options[:class_name]).to eq('User')
    end

    it 'has many events through join table' do
      excuse = Excuse.reflect_on_association(:events)
      expect(excuse.macro).to eq(:has_many)
      expect(excuse.options[:through]).to eq(:events_to_excuses)
    end

    it 'has many reviewers through join table' do
      excuse = Excuse.reflect_on_association(:reviewers)
      expect(excuse.macro).to eq(:has_many)
      expect(excuse.options[:through]).to eq(:reviewers_to_excuses)
    end

    it 'provides event accessor methods' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'https://example.com/proof')
      expect(excuse.event).to eq(event)
      expect(excuse.event_id).to eq(event.id)
    end

    it 'provides reviewed_by accessor methods' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      reviewer = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'https://example.com/proof', 
                          reviewed_by: reviewer)
      expect(excuse.reviewed_by).to eq(reviewer)
      expect(excuse.reviewed_by_id).to eq(reviewer.id)
    end
  end

  describe 'validations' do
    it 'validates presence of reason' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, proof_link: 'https://example.com/proof')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:reason]).to include("can't be blank")
    end

    it 'validates presence of proof_link' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:proof_link]).to include("can't be blank")
    end

    it 'validates proof_link format' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'not-a-url')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:proof_link]).to include("must be a valid URL")
    end

    context 'when recurring is true' do
      let(:user) { create(:user, approval_status: 'approved') }
      let(:base_attrs) { { member: user, reason: 'Recurring absence', proof_link: 'https://example.com/proof', recurring: true } }

      it 'requires start_date' do
        excuse = Excuse.new(base_attrs.merge(end_date: 2.weeks.from_now, recurring_days: '1,3'))
        expect(excuse).not_to be_valid
        expect(excuse.errors[:start_date]).to include("can't be blank")
      end

      it 'requires end_date' do
        excuse = Excuse.new(base_attrs.merge(start_date: 1.week.from_now, recurring_days: '1,3'))
        expect(excuse).not_to be_valid
        expect(excuse.errors[:end_date]).to include("can't be blank")
      end

      it 'requires recurring_days' do
        excuse = Excuse.new(base_attrs.merge(start_date: 1.week.from_now, end_date: 2.weeks.from_now))
        expect(excuse).not_to be_valid
        expect(excuse.errors[:recurring_days]).to include("must have at least one day selected")
      end

      it 'validates end_date must be after start_date' do
        excuse = Excuse.new(base_attrs.merge(start_date: 2.weeks.from_now, end_date: 1.week.from_now, recurring_days: '1,3'))
        expect(excuse).not_to be_valid
        expect(excuse.errors[:end_date]).to include("must be after start date")
      end
    end

    context 'when recurring is false' do
      it 'does not require start_date, end_date, or recurring_days' do
        event = create(:event)
        user = create(:user, approval_status: 'approved')
        excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'https://example.com/proof', recurring: false)
        expect(excuse).to be_valid
      end
    end
  end

  describe 'recurring helper methods' do
    let(:user) { create(:user, approval_status: 'approved') }

    describe '#recurring?' do
      it 'returns true when recurring is true' do
        excuse = Excuse.new(recurring: true)
        expect(excuse.recurring?).to be true
      end

      it 'returns false when recurring is false' do
        excuse = Excuse.new(recurring: false)
        expect(excuse.recurring?).to be false
      end
    end

    describe '#recurring_days_array' do
      it 'parses "1,3,5" into [1, 3, 5]' do
        excuse = Excuse.new(recurring_days: '1,3,5')
        expect(excuse.recurring_days_array).to eq([1, 3, 5])
      end

      it 'returns [] when recurring_days is blank' do
        excuse = Excuse.new(recurring_days: nil)
        expect(excuse.recurring_days_array).to eq([])
      end
    end

    describe '#recurring_day_names' do
      it 'returns human-readable day names' do
        excuse = Excuse.new(recurring_days: '1,3,5')
        expect(excuse.recurring_day_names).to eq('Monday, Wednesday, Friday')
      end
    end

    describe '#find_matching_events' do
      it 'returns events matching day-of-week within date range' do
        # Find the next Monday from today
        next_monday = Time.current.beginning_of_day
        next_monday += 1.day until next_monday.wday == 1
        event_match = create(:event, date: next_monday, end_time: next_monday + 2.hours)
        # Create a Tuesday event (should not match)
        tuesday = next_monday + 1.day
        event_no_match = create(:event, date: tuesday, end_time: tuesday + 2.hours)

        excuse = Excuse.new(
          member: user, recurring: true, recurring_days: '1',
          start_date: next_monday - 1.day, end_date: next_monday + 2.days,
          reason: 'Test', proof_link: 'https://example.com/proof'
        )

        matching = excuse.find_matching_events
        expect(matching).to include(event_match)
        expect(matching).not_to include(event_no_match)
      end

      it 'returns empty when no events match' do
        excuse = Excuse.new(
          member: user, recurring: true, recurring_days: '6',
          start_date: 1.week.from_now, end_date: 2.weeks.from_now,
          reason: 'Test', proof_link: 'https://example.com/proof'
        )
        expect(excuse.find_matching_events).to be_empty
      end
    end

    describe '#cancel_future_events!' do
      it 'removes future event joins and keeps past event joins' do
        past_event = create(:event, date: 1.week.ago, end_time: 1.week.ago + 2.hours)
        future_event = create(:event, date: 1.week.from_now, end_time: 1.week.from_now + 2.hours)

        excuse = Excuse.create!(
          member: user, reason: 'Recurring', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '1,3', start_date: 2.weeks.ago, end_date: 2.weeks.from_now
        )
        excuse.events << past_event
        excuse.events << future_event

        excuse.cancel_future_events!
        excuse.reload

        expect(excuse.events).to include(past_event)
        expect(excuse.events).not_to include(future_event)
      end
    end

    describe '#has_future_events?' do
      it 'returns true when future events exist' do
        future_event = create(:event, date: 1.week.from_now, end_time: 1.week.from_now + 2.hours)
        excuse = Excuse.create!(
          member: user, reason: 'Recurring', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '1,3', start_date: 1.week.ago, end_date: 2.weeks.from_now
        )
        excuse.events << future_event
        expect(excuse.has_future_events?).to be true
      end

      it 'returns false when no future events' do
        past_event = create(:event, date: 1.week.ago, end_time: 1.week.ago + 2.hours)
        excuse = Excuse.create!(
          member: user, reason: 'Recurring', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '1,3', start_date: 2.weeks.ago, end_date: 1.day.ago
        )
        excuse.events << past_event
        expect(excuse.has_future_events?).to be false
      end

      it 'returns false when not recurring' do
        excuse = Excuse.new(recurring: false)
        expect(excuse.has_future_events?).to be false
      end
    end
  end

  describe 'scopes' do
    let(:event) { create(:event) }
    let(:user1) { create(:user, approval_status: 'approved') }
    let(:user2) { create(:user, approval_status: 'approved') }
    let(:user3) { create(:user, approval_status: 'approved') }

    before do
      @approved_excuse = Excuse.create!(member: user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      @pending_excuse = Excuse.create!(member: user2, event: event, reason: 'Doctor', status: 'pending', proof_link: 'https://example.com/proof2')
      @denied_excuse = Excuse.create!(member: user3, event: event, reason: 'Travel', status: 'denied', proof_link: 'https://example.com/proof3')
    end

    describe '.approved' do
      it 'returns only approved excuses' do
        expect(Excuse.approved).to include(@approved_excuse)
        expect(Excuse.approved).not_to include(@pending_excuse, @denied_excuse)
      end
    end

    describe '.pending' do
      it 'returns only pending excuses' do
        expect(Excuse.pending).to include(@pending_excuse)
        expect(Excuse.pending).not_to include(@approved_excuse, @denied_excuse)
      end
    end

    describe '.denied' do
      it 'returns only denied excuses' do
        expect(Excuse.denied).to include(@denied_excuse)
        expect(Excuse.denied).not_to include(@approved_excuse, @pending_excuse)
      end
    end
  end
end

