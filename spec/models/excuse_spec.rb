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
      # Using create to trigger the after_create callbacks
      excuse = Excuse.create!(member: user, events: [event], reason: 'Test', proof_link: 'https://example.com/proof')
      expect(excuse.event).to eq(event)
    end

    it 'provides reviewer entries' do
      user = create(:user, approval_status: 'approved')
      reviewer = create(:user, :officer)
      excuse = create(:excuse, member: user)
      excuse.add_reviewer(reviewer)
      expect(excuse.reviewer_entries.first.reviewer).to eq(reviewer)
    end
  end

  describe 'validations' do
    it 'validates presence of reason' do
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, proof_link: 'https://example.com/proof')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:reason]).to include("can't be blank")
    end

    it 'validates presence of proof_link' do
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, reason: 'Test')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:proof_link]).to include("can't be blank")
    end

    it 'validates proof_link format' do
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, reason: 'Test', proof_link: 'not-a-url')
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
    end

    context 'when recurring is false' do
      it 'does not require start_date, end_date, or recurring_days' do
        user = create(:user, approval_status: 'approved')
        excuse = Excuse.new(member: user, reason: 'Test', proof_link: 'https://example.com/proof', recurring: false)
        expect(excuse).to be_valid
      end
    end
  end

  describe 'Story A3 logic and status transitions' do
    let(:member) { create(:user, approval_status: 'approved') }

    it "defaults status to 'Pending Section Leader Review' on creation (AC 1)" do
      excuse = Excuse.create!(member: member, reason: "Sick", proof_link: "https://test.com")
      expect(excuse.status).to eq('Pending Section Leader Review')
    end

    it "allows an officer to set a provisional decision" do
      officer = create(:user, :officer)
      excuse = create(:excuse, member: member)
      
      excuse.set_officer_decision(officer, 'approved')
      expect(excuse.officer_status).to eq('approved')
      expect(excuse.officer_reviewed_at).to be_present
      expect(excuse.reviewers).to include(officer)
    end

    it "allows a director to finalize a decision (AC 5)" do
      director = create(:user, :super_admin)
      excuse = create(:excuse, member: member)

      excuse.finalize_by_admin(director, 'denied')
      expect(excuse.status).to eq('denied')
      expect(excuse.reviewed_date).to be_present
      expect(excuse.reviewers).to include(director)
    end

    it "allows an officer to set a provisional denial" do
      officer = create(:user, :officer)
      excuse = create(:excuse, member: member)

      excuse.set_officer_decision(officer, 'denied')
      expect(excuse.officer_status).to eq('denied')
      expect(excuse.officer_reviewed_at).to be_present
      expect(excuse.reviewers).to include(officer)
    end

    it "rejects invalid decisions for officer" do
      officer = create(:user, :officer)
      excuse = create(:excuse, member: member)

      result = excuse.set_officer_decision(officer, 'invalid')
      expect(result).to be false
      expect(excuse.officer_status).to be_nil
    end

    it "rejects invalid decisions for director" do
      director = create(:user, :super_admin)
      excuse = create(:excuse, member: member)

      result = excuse.finalize_by_admin(director, 'invalid')
      expect(result).to be false
    end

    it "prevents duplicate reviewers" do
      officer = create(:user, :officer)
      excuse = create(:excuse, member: member)

      excuse.add_reviewer(officer)
      result = excuse.add_reviewer(officer)
      expect(result).to be false
      expect(excuse.reviewers.where(id: officer.id).count).to eq(1)
    end
  end

  describe 'Attendance Synchronization' do
    let(:event) { create(:event) }
    let(:member) { create(:user, approval_status: 'approved') }
    let(:excuse) { create(:excuse, member: member, events: [event]) }

    it "automatically creates an 'excused' attendance record when status becomes approved" do
      excuse.update!(status: 'approved')
      attendance = Attendance.find_by(user_id: member.id, event_id: event.id)
      expect(attendance).to be_present
      expect(attendance.status).to eq('excused')
    end

    it "reverts attendance to 'absent' if an approved excuse is changed/revoked" do
      excuse.update!(status: 'approved') # Initially excused
      excuse.update!(status: 'denied')   # Revoked
      attendance = Attendance.find_by(user_id: member.id, event_id: event.id)
      expect(attendance.status).to eq('absent')
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

    describe '#future_events?' do
      it 'returns true when future events exist' do
        future_event = create(:event, date: 1.week.from_now, end_time: 1.week.from_now + 2.hours)
        excuse = Excuse.create!(
          member: user, reason: 'Recurring', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '1,3', start_date: 1.week.ago, end_date: 2.weeks.from_now
        )
        excuse.events << future_event
        expect(excuse.future_events?).to be true
      end
    end
  end

  describe 'scopes' do
    let(:event) { create(:event) }
    let(:user1) { create(:user, approval_status: 'approved') }
    let(:user2) { create(:user, approval_status: 'approved') }
    let(:user3) { create(:user, approval_status: 'approved') }

    before do
      # Bypassing validation to set specific statuses for scope testing
      @approved_excuse = Excuse.create!(member: user1, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      @pending_excuse = Excuse.create!(member: user2, reason: 'Doctor', status: 'pending', proof_link: 'https://example.com/proof2')
      @denied_excuse = Excuse.create!(member: user3, reason: 'Travel', status: 'denied', proof_link: 'https://example.com/proof3')
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

    describe '.pending_admin_approval' do
      it 'returns excuses with pending status and officer_status present' do
        @pending_excuse.update_columns(officer_status: 'approved')
        expect(Excuse.pending_admin_approval).to include(@pending_excuse)
        expect(Excuse.pending_admin_approval).not_to include(@approved_excuse, @denied_excuse)
      end

      it 'excludes pending excuses without officer_status' do
        expect(Excuse.pending_admin_approval).not_to include(@pending_excuse)
      end
    end

    describe '.pending_unprocessed' do
      it 'returns excuses with Pending Section Leader Review status' do
        user4 = create(:user, approval_status: 'approved')
        unprocessed = Excuse.create!(member: user4, reason: 'New', proof_link: 'https://example.com/proof4')
        expect(Excuse.pending_unprocessed).to include(unprocessed)
        expect(Excuse.pending_unprocessed).not_to include(@approved_excuse, @pending_excuse, @denied_excuse)
      end
    end
  end

  describe 'full 2-step approval flow (officer → director)' do
    let(:section) { create(:section, name: 'Tenor 1') }
    let(:member) { create(:user, approval_status: 'approved', section: section) }
    let(:officer) { create(:user, :officer, section: section) }
    let(:director) { create(:user, :super_admin) }
    let(:event) { create(:event) }

    it 'walks through the complete approval pipeline' do
      # Step 0: Member creates excuse — defaults to "Pending Section Leader Review"
      excuse = Excuse.create!(member: member, events: [event], reason: 'Sick', proof_link: 'https://example.com/proof')
      expect(excuse.status).to eq('Pending Section Leader Review')

      # Step 1: Officer makes provisional approval
      excuse.set_officer_decision(officer, 'approved')
      excuse.update!(status: 'pending')
      expect(excuse.officer_status).to eq('approved')
      expect(excuse.status).to eq('pending')
      expect(excuse.reviewers).to include(officer)

      # Step 2: Director finalizes
      excuse.finalize_by_admin(director, 'approved')
      expect(excuse.status).to eq('approved')
      expect(excuse.reviewers).to include(director)

      # Attendance should be synced
      attendance = Attendance.find_by(user_id: member.id, event_id: event.id)
      expect(attendance).to be_present
      expect(attendance.status).to eq('excused')
    end

    it 'allows director to override officer provisional denial' do
      excuse = Excuse.create!(member: member, events: [event], reason: 'Sick', proof_link: 'https://example.com/proof')

      # Officer denies
      excuse.set_officer_decision(officer, 'denied')
      excuse.update!(status: 'pending')
      expect(excuse.officer_status).to eq('denied')

      # Director overrides with approval
      excuse.finalize_by_admin(director, 'approved')
      expect(excuse.status).to eq('approved')

      attendance = Attendance.find_by(user_id: member.id, event_id: event.id)
      expect(attendance.status).to eq('excused')
    end
  end
end