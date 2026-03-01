# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Event, type: :model do
  it 'is valid with a title and date' do
    event = Event.new(title: 'Sample Event', date: Time.zone.today, end_time: Time.zone.today + 2.hours)
    expect(event).to be_valid
  end

  it 'is invalid without a title' do
    event = Event.new(date: Time.zone.today, end_time: Time.zone.today + 2.hours)
    expect(event).not_to be_valid
    expect(event.errors[:title]).to include("can't be blank")
  end

  it 'is invalid without a date' do
    event = Event.new(title: 'Sample Event', end_time: Time.zone.today + 2.hours)
    expect(event).not_to be_valid
    expect(event.errors[:date]).to include("can't be blank")
  end

  it "is invalid if end_time is before date" do
    event = Event.new(title: "Test", date: Time.now, end_time: 1.hour.ago)
    expect(event).not_to be_valid
    expect(event.errors[:end_time]).to include("must be after the start time")
  end

  describe '.upcoming' do
    it 'returns events with dates today or in the future' do
      past_event = Event.create!(title: 'Past Event', date: Date.yesterday, end_time: Date.yesterday + 2.hours)
      today_event = Event.create!(title: 'Today Event', date: Time.zone.today, end_time: Time.zone.today + 2.hours)
      future_event = Event.create!(title: 'Future Event', date: Date.tomorrow, end_time: Date.tomorrow + 2.hours)

      expect(Event.upcoming).to include(today_event, future_event)
      expect(Event.upcoming).not_to include(past_event)
    end
  end

  describe '.past' do
    it 'returns events with dates in the past' do
      past_event = Event.create!(title: 'Past Event', date: Date.yesterday, end_time: Date.yesterday + 2.hours)
      today_event = Event.create!(title: 'Today Event', date: Time.zone.today, end_time: Time.zone.today + 2.hours)
      future_event = Event.create!(title: 'Future Event', date: Date.tomorrow, end_time: Date.tomorrow + 2.hours)

      expect(Event.past).to include(past_event)
      expect(Event.past).not_to include(today_event, future_event)
    end
  end

  describe '#attendance_stats' do
    it 'returns correct attendance statistics' do
      event = create(:event)
      create_list(:attendance, 3, event: event, status: 'present')
      create_list(:attendance, 2, event: event, status: 'absent')
      create_list(:attendance, 1, event: event, status: 'excused')

      stats = event.attendance_stats
      expect(stats[:total]).to eq(6)
      expect(stats[:present]).to eq(3)
      expect(stats[:absent]).to eq(2)
      expect(stats[:excused]).to eq(1)
      expect(stats[:present_percentage]).to eq(50.0)
    end

    it 'handles zero attendances' do
      event = create(:event)
      stats = event.attendance_stats
      expect(stats[:total]).to eq(0)
      expect(stats[:present]).to eq(0)
      expect(stats[:absent]).to eq(0)
      expect(stats[:excused]).to eq(0)
      expect(stats[:present_percentage]).to eq(0)
    end
  end

  describe '#approved_excuses' do
    it 'returns only approved excuses for the event' do
      event = create(:event)
      user1 = create(:user, approval_status: 'approved')
      user2 = create(:user, approval_status: 'approved')
      user3 = create(:user, approval_status: 'approved')
      
      approved_excuse = Excuse.create!(member: user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      pending_excuse = Excuse.create!(member: user2, event: event, reason: 'Doctor', status: 'pending', proof_link: 'https://example.com/proof2')
      denied_excuse = Excuse.create!(member: user3, event: event, reason: 'Travel', status: 'denied', proof_link: 'https://example.com/proof3')

      expect(event.approved_excuses).to include(approved_excuse)
      expect(event.approved_excuses).not_to include(pending_excuse, denied_excuse)
    end
  end

  describe '#approved_excuses_count' do
    it 'returns the count of approved excuses' do
      event = create(:event)
      user1 = create(:user, approval_status: 'approved')
      user2 = create(:user, approval_status: 'approved')
      user3 = create(:user, approval_status: 'approved')
      
      Excuse.create!(member: user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      Excuse.create!(member: user2, event: event, reason: 'Doctor', status: 'approved', proof_link: 'https://example.com/proof2')
      Excuse.create!(member: user3, event: event, reason: 'Travel', status: 'pending', proof_link: 'https://example.com/proof3')

      expect(event.approved_excuses_count).to eq(2)
    end
  end

  describe '#user_has_approved_excuse?' do
    it 'returns true if user has an approved excuse' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof')

      expect(event.user_has_approved_excuse?(user)).to be true
    end

    it 'returns false if user has no approved excuse' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'pending', proof_link: 'https://example.com/proof')

      expect(event.user_has_approved_excuse?(user)).to be false
    end

    it 'returns false if user has no excuse' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')

      expect(event.user_has_approved_excuse?(user)).to be false
    end
  end

  describe '#users_with_approved_excuses' do
    it 'returns users who have approved excuses for the event' do
      event = create(:event)
      user1 = create(:user, approval_status: 'approved')
      user2 = create(:user, approval_status: 'approved')
      user3 = create(:user, approval_status: 'approved')
      
      Excuse.create!(member: user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      Excuse.create!(member: user2, event: event, reason: 'Doctor', status: 'approved', proof_link: 'https://example.com/proof2')
      Excuse.create!(member: user3, event: event, reason: 'Travel', status: 'pending', proof_link: 'https://example.com/proof3')

      users = event.users_with_approved_excuses
      expect(users).to include(user1, user2)
      expect(users).not_to include(user3)
    end
  end
  describe '#link_to_matching_recurring_excuses' do
    let(:member) { create(:user) }

    # A Monday within the recurring range
    let(:monday_in_range) { Date.parse('2026-03-09') } # Monday

    let!(:recurring_excuse) do
      Excuse.create!(
        member: member,
        recurring: true,
        recurring_days: '1', # Monday = 1
        start_date: Date.parse('2026-03-02'),
        end_date: Date.parse('2026-03-30'),
        status: 'pending',
        reason: 'Recurring absence',
        proof_link: 'https://example.com/proof'
      )
    end

    it 'auto-links a new event on a matching day within the date range' do
      event = Event.create!(title: 'Monday Practice', date: monday_in_range.to_time, end_time: monday_in_range.to_time + 2.hours)
      expect(recurring_excuse.events.reload).to include(event)
    end

    it 'does not link an event outside the date range' do
      out_of_range = Date.parse('2026-04-06') # Monday, after end_date
      event = Event.create!(title: 'Late Monday', date: out_of_range.to_time, end_time: out_of_range.to_time + 2.hours)
      expect(recurring_excuse.events.reload).not_to include(event)
    end

    it 'does not link an event on a non-matching day' do
      tuesday = Date.parse('2026-03-10') # Tuesday = 2, not in recurring_days
      event = Event.create!(title: 'Tuesday Practice', date: tuesday.to_time, end_time: tuesday.to_time + 2.hours)
      expect(recurring_excuse.events.reload).not_to include(event)
    end

    it 'marks attendance as excused when excuse is already approved' do
      recurring_excuse.update!(status: 'approved')
      event = Event.create!(title: 'Monday Practice', date: monday_in_range.to_time, end_time: monday_in_range.to_time + 2.hours)

      attendance = Attendance.find_by(event: event, user: member)
      expect(attendance).to be_present
      expect(attendance.status).to eq('excused')
    end

    it 'does not create attendance for a pending excuse' do
      event = Event.create!(title: 'Monday Practice', date: monday_in_range.to_time, end_time: monday_in_range.to_time + 2.hours)

      attendance = Attendance.find_by(event: event, user: member)
      expect(attendance).to be_nil
    end

    it 'does not create duplicate links' do
      event = Event.create!(title: 'Monday Practice', date: monday_in_range.to_time, end_time: monday_in_range.to_time + 2.hours)
      expect(recurring_excuse.events.reload.where(id: event.id).count).to eq(1)

      # Manually trigger the callback again to simulate a duplicate scenario
      event.send(:link_to_matching_recurring_excuses)
      expect(recurring_excuse.events.reload.where(id: event.id).count).to eq(1)
    end
  end

  describe 'self check-in functionality' do
    describe 'passcode generation' do
      it 'automatically generates a 4-digit passcode when allow_self_checkin is enabled' do
        event = build(:event, allow_self_checkin: true, checkin_passcode: nil)
        event.save
        expect(event.checkin_passcode).to match(/^\d{4}$/)
      end

      it 'does not generate a passcode when allow_self_checkin is false' do
        event = build(:event, allow_self_checkin: false, checkin_passcode: nil)
        event.save
        expect(event.checkin_passcode).to be_nil
      end

      it 'does not overwrite existing passcode' do
        event = build(:event, allow_self_checkin: true, checkin_passcode: '5678')
        event.save
        expect(event.checkin_passcode).to eq('5678')
      end
    end

    describe 'passcode validation' do
      it 'is valid with a 4-digit passcode when allow_self_checkin is true' do
        event = build(:event, allow_self_checkin: true, checkin_passcode: '1234')
        expect(event).to be_valid
      end

      it 'is invalid with non-4-digit passcode when allow_self_checkin is true' do
        event = build(:event, allow_self_checkin: true, checkin_passcode: '123')
        expect(event).not_to be_valid
        expect(event.errors[:checkin_passcode]).to include('must be a 4-digit number')
      end

      it 'is invalid with non-numeric passcode when allow_self_checkin is true' do
        event = build(:event, allow_self_checkin: true, checkin_passcode: 'abcd')
        expect(event).not_to be_valid
        expect(event.errors[:checkin_passcode]).to include('must be a 4-digit number')
      end

      it 'does not validate passcode when allow_self_checkin is false' do
        event = build(:event, allow_self_checkin: false, checkin_passcode: 'invalid')
        expect(event).to be_valid
      end
    end

    describe '#self_checkin_available?' do
      it 'returns true when within check-in window (10 min before to 10 min after)' do
        event = create(:event, :self_checkin_available)
        expect(event.self_checkin_available?).to be true
      end

      it 'returns false when before check-in window' do
        event = create(:event, :self_checkin_before_window)
        expect(event.self_checkin_available?).to be false
      end

      it 'returns false when after check-in window' do
        event = create(:event, :self_checkin_after_window)
        expect(event.self_checkin_available?).to be false
      end

      it 'returns false when allow_self_checkin is false' do
        event = create(:event, 
          allow_self_checkin: false,
          date: 5.minutes.from_now,
          end_time: 1.hour.from_now
        )
        expect(event.self_checkin_available?).to be false
      end

      it 'returns true at exactly 10 minutes before event' do
        event = create(:event, :with_self_checkin,
          date: 10.minutes.from_now,
          end_time: 1.hour.from_now
        )
        expect(event.self_checkin_available?).to be true
      end

      it 'returns true at exactly 10 minutes after event end' do
        event = create(:event, :with_self_checkin,
          date: 1.hour.ago,
          end_time: 10.minutes.from_now
        )
        expect(event.self_checkin_available?).to be true
      end
    end

    describe '#verify_passcode' do
      let(:event) { create(:event, :with_self_checkin) }

      it 'returns true with correct passcode' do
        expect(event.verify_passcode('1234')).to be true
      end

      it 'returns false with incorrect passcode' do
        expect(event.verify_passcode('0000')).to be false
      end

      it 'returns false with empty passcode' do
        expect(event.verify_passcode('')).to be false
      end

      it 'returns false when event has no passcode' do
        event = create(:event, allow_self_checkin: false, checkin_passcode: nil)
        expect(event.verify_passcode('1234')).to be false
      end

      it 'handles passcode with whitespace' do
        expect(event.verify_passcode(' 1234 ')).to be true
      end
    end
  end
end
