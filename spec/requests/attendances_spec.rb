# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Attendances', type: :request do
  let(:user) { create(:user, approval_status: 'approved') }
  let(:admin_user) { create(:user, :officer) }
  let(:event) { create(:event) }

  describe 'GET /new' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'renders a successful response' do
        get new_internal_event_attendance_path(event)
        expect(response).to be_successful
      end

      context 'with approved excuses' do
        let(:excused_user1) { create(:user, approval_status: 'approved') }
        let(:excused_user2) { create(:user, approval_status: 'approved') }

        before do
          Excuse.create!(member: excused_user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
          Excuse.create!(member: excused_user2, event: event, reason: 'Doctor', status: 'approved', proof_link: 'https://example.com/proof2')
        end

        it 'pre-populates excused status for users with approved excuses' do
          get new_internal_event_attendance_path(event)
          expect(response).to be_successful
          expect(response.body).to include('Approved Excuse')
          expect(response.body).to include(excused_user1.full_name)
          expect(response.body).to include(excused_user2.full_name)
        end

        it 'shows alert message for excused users' do
          get new_internal_event_attendance_path(event)
          expect(response).to be_successful
          expect(response.body).to include('approved excuses and will be marked as excused')
        end

        it 'disables radio buttons for excused users' do
          get new_internal_event_attendance_path(event)
          expect(response).to be_successful
          expect(response.body).to include('disabled')
        end
      end

      context 'with no approved members' do
        it 'still renders the attendance form' do
          get new_internal_event_attendance_path(event)
          expect(response).to be_successful
        end
      end
    end

    context 'as regular user' do
      before { sign_in user }

      it 'denies access' do
        get new_internal_event_attendance_path(event)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to sign in' do
        get new_internal_event_attendance_path(event)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'POST /create' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'creates attendance records' do
        user1 = create(:user, approval_status: 'approved')
        user2 = create(:user, approval_status: 'approved')

        expect do
          post internal_event_attendances_path(event), params: {
            attendances: {
              user1.id => { status: 'present', note: '' },
              user2.id => { status: 'absent', note: '' }
            }
          }
        end.to change(Attendance, :count).by(2)
      end

      it 'preserves excused status for users with approved excuses' do
        excused_user = create(:user, approval_status: 'approved')
        Excuse.create!(member: excused_user, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof')

        post internal_event_attendances_path(event), params: {
          attendances: {
            excused_user.id => { status: 'excused', note: '' }
          }
        }

        attendance = Attendance.find_by(user_id: excused_user.id, event_id: event.id)
        expect(attendance.status).to eq('excused')
      end

      it 'redirects to event after successful creation' do
        user1 = create(:user, approval_status: 'approved')

        post internal_event_attendances_path(event), params: {
          attendances: {
            user1.id => { status: 'present', note: 'Test note' }
          }
        }

        expect(response).to redirect_to(internal_event_path(event))
      end

      it 'stores notes with attendance' do
        user1 = create(:user, approval_status: 'approved')

        post internal_event_attendances_path(event), params: {
          attendances: {
            user1.id => { status: 'present', note: 'Test note' }
          }
        }

        attendance = Attendance.find_by(user_id: user1.id, event_id: event.id)
        expect(attendance.note).to eq('Test note')
      end

      it 'updates existing attendance records instead of duplicating' do
        user1 = create(:user, approval_status: 'approved')
        create(:attendance, user: user1, event: event, status: 'absent')

        expect do
          post internal_event_attendances_path(event), params: {
            attendances: {
              user1.id => { status: 'present', note: 'Updated' }
            }
          }
        end.not_to change(Attendance, :count)

        attendance = Attendance.find_by(user_id: user1.id, event_id: event.id)
        expect(attendance.status).to eq('present')
      end
    end

    context 'as regular user' do
      before { sign_in user }

      it 'denies access' do
        post internal_event_attendances_path(event), params: {
          attendances: {
            user.id => { status: 'present', note: '' }
          }
        }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PUT /update' do
    context 'as admin user' do
      before { sign_in admin_user }

      it 'redirects to new attendance path' do
        put internal_event_attendance_path(event, id: 1)
        expect(response).to redirect_to(new_internal_event_attendance_path(event))
      end
    end
  end

  describe 'Self Check-in functionality' do
    let(:member_user) { create(:user, approval_status: 'approved') }
    let(:event_with_checkin) { create(:event, :self_checkin_available) }

    describe 'GET /internal/events/:id/self_checkin' do
      context 'when user is signed in' do
        before { sign_in member_user }

        it 'renders the self check-in form' do
          get self_checkin_internal_event_path(event_with_checkin)
          expect(response).to be_successful
        end

        it 'redirects if self check-in is not enabled' do
          event_no_checkin = create(:event, allow_self_checkin: false)
          get self_checkin_internal_event_path(event_no_checkin)
          expect(response).to redirect_to(internal_events_path)
          expect(flash[:error]).to include('Self check-in is not enabled')
        end

        it 'redirects if self check-in window has not started' do
          event_future = create(:event, :self_checkin_before_window)
          get self_checkin_internal_event_path(event_future)
          expect(response).to redirect_to(internal_events_path)
          expect(flash[:error]).to include('Self check-in is not currently available')
        end

        it 'redirects if self check-in window has ended' do
          event_past = create(:event, :self_checkin_after_window)
          get self_checkin_internal_event_path(event_past)
          expect(response).to redirect_to(internal_events_path)
          expect(flash[:error]).to include('Self check-in is not currently available')
        end

        it 'redirects if user has already checked in' do
          create(:attendance, event: event_with_checkin, user: member_user, status: 'present')
          get self_checkin_internal_event_path(event_with_checkin)
          expect(response).to redirect_to(internal_events_path)
          expect(flash[:notice]).to include('already checked in')
        end
      end

      context 'when user is not signed in' do
        it 'redirects to sign in page' do
          get self_checkin_internal_event_path(event_with_checkin)
          expect(response).to redirect_to('/users/sign_in')
        end
      end
    end

    describe 'POST /internal/events/:id/self_checkin' do
      context 'when user is signed in' do
        before { sign_in member_user }

        it 'creates attendance record with correct passcode' do
          expect do
            post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '1234' }
          end.to change(Attendance, :count).by(1)

          attendance = Attendance.last
          expect(attendance.user).to eq(member_user)
          expect(attendance.event).to eq(event_with_checkin)
          expect(attendance.status).to eq('present')
        end

        it 'redirects to events page after successful check-in' do
          post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '1234' }
          expect(response).to redirect_to(internal_events_path)
          expect(flash[:success]).to include('Successfully checked in')
        end

        it 'rejects incorrect passcode' do
          expect do
            post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '0000' }
          end.not_to change(Attendance, :count)

          expect(response).to redirect_to(self_checkin_internal_event_path(event_with_checkin))
          expect(flash[:error]).to include('Invalid passcode')
        end

        it 'rejects empty passcode' do
          expect do
            post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '' }
          end.not_to change(Attendance, :count)

          expect(response).to redirect_to(self_checkin_internal_event_path(event_with_checkin))
          expect(flash[:error]).to include('Invalid passcode')
        end

        it 'prevents duplicate check-ins' do
          create(:attendance, event: event_with_checkin, user: member_user, status: 'present')

          expect do
            post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '1234' }
          end.not_to change(Attendance, :count)

          expect(response).to redirect_to(internal_events_path)
          expect(flash[:notice]).to include('already checked in')
        end

        it 'rejects check-in outside time window' do
          event_past = create(:event, :self_checkin_after_window)

          expect do
            post self_checkin_internal_event_path(event_past), params: { passcode: '1234' }
          end.not_to change(Attendance, :count)

          expect(response).to redirect_to(self_checkin_internal_event_path(event_past))
          expect(flash[:error]).to include('Self check-in is not currently available')
        end

        it 'rejects check-in when not enabled' do
          event_no_checkin = create(:event, allow_self_checkin: false)

          expect do
            post self_checkin_internal_event_path(event_no_checkin), params: { passcode: '1234' }
          end.not_to change(Attendance, :count)

          expect(response).to redirect_to(internal_events_path)
          expect(flash[:error]).to include('Self check-in is not enabled')
        end
      end

      context 'when user is not signed in' do
        it 'redirects to sign in page' do
          post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '1234' }
          expect(response).to redirect_to('/users/sign_in')
        end
      end

      context 'as admin user' do
        before { sign_in admin_user }

        it 'allows admin to check themselves in' do
          expect do
            post self_checkin_internal_event_path(event_with_checkin), params: { passcode: '1234' }
          end.to change(Attendance, :count).by(1)

          attendance = Attendance.last
          expect(attendance.user).to eq(admin_user)
          expect(attendance.status).to eq('present')
        end
      end
    end
  end
end
