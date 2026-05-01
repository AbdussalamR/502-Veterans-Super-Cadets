# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::SmsMessageBuilder do
  let(:actor) { build(:user, full_name: 'Director Smith') }

  describe 'event notifications (all members)' do
    it 'builds event_created with title, date, time and location' do
      context = {
        'title' => 'Choir Practice', 'date_label' => 'Monday, May 4 at 12:05 AM',
        'end_time_label' => '1:05 PM', 'location' => 'Zoom', 'description' => 'Weekly rehearsal'
      }
      result = described_class.build(event_key: 'event_created', actor: actor, context: context)
      expect(result).to include('Choir Practice', 'Monday, May 4', 'Zoom', 'Weekly rehearsal')
    end

    it 'builds event_cancelled with title, date and location' do
      context = { 'title' => 'Concert', 'date_label' => 'Friday, May 8', 'location' => 'Kyle Field' }
      result = described_class.build(event_key: 'event_cancelled', actor: actor, context: context)
      expect(result).to include('Canceled', 'Concert', 'Friday, May 8', 'Kyle Field')
    end

    it 'builds event_reminder with date and time' do
      context = {
        'title' => 'Choir Practice', 'date_label' => 'Monday, May 4 at 12:05 AM',
        'end_time_label' => '1:05 PM', 'location' => nil, 'description' => nil
      }
      result = described_class.build(event_key: 'event_reminder', actor: actor, context: context)
      expect(result).to include('Reminder', 'Choir Practice', 'Monday, May 4')
    end

    it 'builds event_series_created with count, title and date range' do
      context = {
        'title' => 'Weekly Rehearsal', 'occurrence_count' => 8,
        'first_date_label' => 'Mon May 4', 'last_date_label' => 'Mon Jun 22', 'location' => 'MSC'
      }
      result = described_class.build(event_key: 'event_series_created', actor: actor, context: context)
      expect(result).to include('8', 'Weekly Rehearsal', 'Mon May 4', 'Mon Jun 22', 'MSC')
    end
  end

  describe 'registration notifications' do
    it 'builds registration_pending_admin with name and email' do
      context = { 'full_name' => 'John Smith', 'email' => 'john@tamu.edu' }
      result = described_class.build(event_key: 'registration_pending_admin', actor: nil, context: context)
      expect(result).to include('John Smith', 'john@tamu.edu')
    end

    it 'builds registration_approved with actor name' do
      result = described_class.build(event_key: 'registration_approved', actor: actor, context: {})
      expect(result).to include('Director Smith', 'approved')
    end

    it 'builds registration_rejected with actor name' do
      result = described_class.build(event_key: 'registration_rejected', actor: actor, context: {})
      expect(result).to include('Director Smith', 'rejected')
    end
  end

  describe 'excuse notifications' do
    let(:excuse_context) do
      { 'member_name' => 'Jane Doe', 'event_summary' => 'Choir Practice, Concert', 'officer_status' => 'Approved' }
    end

    it 'builds excuse_submitted_for_review for officers' do
      result = described_class.build(event_key: 'excuse_submitted_for_review', actor: actor, context: excuse_context)
      expect(result).to include('Jane Doe', 'section review', 'Choir Practice, Concert')
    end

    it 'builds excuse_submitted_for_director_review for directors' do
      result = described_class.build(event_key: 'excuse_submitted_for_director_review', actor: actor, context: excuse_context)
      expect(result).to include('Jane Doe', 'director review', 'Choir Practice, Concert')
    end

    it 'builds excuse_pending_admin_review with officer decision' do
      result = described_class.build(event_key: 'excuse_pending_admin_review', actor: actor, context: excuse_context)
      expect(result).to include('Jane Doe', 'Approved', 'Choir Practice, Concert')
    end

    it 'builds excuse_approved for the member' do
      result = described_class.build(event_key: 'excuse_approved', actor: actor, context: excuse_context)
      expect(result).to include('Director Smith', 'approved', 'Choir Practice, Concert')
    end

    it 'builds excuse_denied for the member' do
      result = described_class.build(event_key: 'excuse_denied', actor: actor, context: excuse_context)
      expect(result).to include('Director Smith', 'denied', 'Choir Practice, Concert')
    end
  end

  describe 'demerit notifications (member only)' do
    let(:demerit_context) do
      { 'value' => 1, 'date_label' => 'May 1, 2026', 'reason' => 'Missed rehearsal' }
    end

    it 'builds demerit_created with points and reason' do
      result = described_class.build(event_key: 'demerit_created', actor: actor, context: demerit_context)
      expect(result).to include('1', 'May 1, 2026', 'Missed rehearsal')
    end

    it 'builds demerit_updated with reason' do
      result = described_class.build(event_key: 'demerit_updated', actor: actor, context: demerit_context)
      expect(result).to include('updated', 'Missed rehearsal')
    end

    it 'builds demerit_deleted with reason' do
      result = described_class.build(event_key: 'demerit_deleted', actor: actor, context: demerit_context)
      expect(result).to include('removed', 'Missed rehearsal')
    end
  end

  describe 'performance request (directors only)' do
    it 'builds performance_request_submitted with requester and org' do
      context = {
        'requester_name' => 'John Smith', 'organization' => 'Texas A&M Band',
        'event_date' => 'May 10, 2026', 'location' => 'Kyle Field'
      }
      result = described_class.build(event_key: 'performance_request_submitted', actor: nil, context: context)
      expect(result).to include('John Smith', 'Texas A&M Band', 'May 10, 2026', 'Kyle Field')
    end
  end

  it 'returns nil for an unknown event key' do
    result = described_class.build(event_key: 'unknown_key', actor: actor, context: {})
    expect(result).to be_nil
  end
end
