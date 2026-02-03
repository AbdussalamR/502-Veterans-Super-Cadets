# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EventsHelper, type: :helper do
  describe '#attendance_status_badge' do
    let(:user) { create(:user, approval_status: 'approved') }
    let(:event) { create(:event) }

    context 'when user is nil' do
      it 'returns empty string' do
        badge = helper.attendance_status_badge(nil, event)
        expect(badge).to eq('')
      end
    end

    context 'when user has attendance recorded as present' do
      before do
        create(:attendance, user: user, event: event, status: 'present')
      end

      it 'returns a success badge' do
        badge = helper.attendance_status_badge(user, event)
        expect(badge).to include('badge bg-success')
        expect(badge).to include('Present')
      end
    end

    context 'when user has attendance recorded as absent' do
      before do
        create(:attendance, user: user, event: event, status: 'absent')
      end

      it 'returns a danger badge' do
        badge = helper.attendance_status_badge(user, event)
        expect(badge).to include('badge bg-danger')
        expect(badge).to include('Absent')
      end
    end

    context 'when user has attendance recorded as excused' do
      before do
        create(:attendance, user: user, event: event, status: 'excused')
      end

      it 'returns a warning badge' do
        badge = helper.attendance_status_badge(user, event)
        expect(badge).to include('badge bg-warning')
        expect(badge).to include('Excused')
      end
    end

    context 'when user has no attendance recorded' do
      it 'returns a secondary badge' do
        badge = helper.attendance_status_badge(user, event)
        expect(badge).to include('badge bg-secondary')
        expect(badge).to include('Not Recorded')
      end
    end
  end
end
