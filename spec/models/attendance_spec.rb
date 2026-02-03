# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attendance, type: :model do
  describe 'associations' do
    it 'belongs to user' do
      attendance = Attendance.reflect_on_association(:user)
      expect(attendance.macro).to eq(:belongs_to)
    end

    it 'belongs to event' do
      attendance = Attendance.reflect_on_association(:event)
      expect(attendance.macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    let(:user) { create(:user, approval_status: 'approved') }
    let(:event) { create(:event) }

    it 'validates presence of status' do
      attendance = Attendance.new(user: user, event: event, status: nil)
      expect(attendance).not_to be_valid
      expect(attendance.errors[:status]).to include("can't be blank")
    end

    it 'validates inclusion of status in STATUSES' do
      attendance = Attendance.new(user: user, event: event, status: 'invalid')
      expect(attendance).not_to be_valid
      expect(attendance.errors[:status]).to include('is not included in the list')
    end

    it 'validates uniqueness of user_id scoped to event_id' do
      create(:attendance, user: user, event: event, status: 'present')
      duplicate = Attendance.new(user: user, event: event, status: 'absent')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('already has attendance recorded for this event')
    end
  end

  describe 'scopes' do
    let(:event) { create(:event) }
    let(:user1) { create(:user, approval_status: 'approved') }
    let(:user2) { create(:user, approval_status: 'approved') }
    let(:user3) { create(:user, approval_status: 'approved') }

    before do
      create(:attendance, user: user1, event: event, status: 'present')
      create(:attendance, user: user2, event: event, status: 'absent')
      create(:attendance, user: user3, event: event, status: 'excused')
    end

    describe '.present' do
      it 'returns only present attendances' do
        expect(Attendance.present.count).to eq(1)
        expect(Attendance.present.first.status).to eq('present')
      end
    end

    describe '.absent' do
      it 'returns only absent attendances' do
        expect(Attendance.absent.count).to eq(1)
        expect(Attendance.absent.first.status).to eq('absent')
      end
    end

    describe '.excused' do
      it 'returns only excused attendances' do
        expect(Attendance.excused.count).to eq(1)
        expect(Attendance.excused.first.status).to eq('excused')
      end
    end
  end

  describe '.record_for_event' do
    let(:event) { create(:event) }
    let(:user1) { create(:user, approval_status: 'approved') }
    let(:user2) { create(:user, approval_status: 'approved') }

    it 'creates attendance records for multiple users' do
      attendances_hash = {
        user1.id => 'present',
        user2.id => 'absent'
      }

      expect {
        Attendance.record_for_event(event.id, attendances_hash)
      }.to change(Attendance, :count).by(2)

      expect(Attendance.find_by(user_id: user1.id, event_id: event.id).status).to eq('present')
      expect(Attendance.find_by(user_id: user2.id, event_id: event.id).status).to eq('absent')
    end

    it 'updates existing attendance records' do
      create(:attendance, user: user1, event: event, status: 'absent')
      
      attendances_hash = {
        user1.id => 'present'
      }

      expect {
        Attendance.record_for_event(event.id, attendances_hash)
      }.not_to change(Attendance, :count)

      expect(Attendance.find_by(user_id: user1.id, event_id: event.id).status).to eq('present')
    end
  end
end

