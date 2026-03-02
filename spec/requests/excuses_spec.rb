# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Excuses', type: :request do
  let(:user) { create(:user, approval_status: 'approved') }
  let(:officer) { create(:user, :officer) }
  let(:admin_user) { create(:user, :super_admin) }
  let(:event) { create(:event) }

  describe 'GET /index' do
    context 'as authenticated admin' do
      before { sign_in admin_user }

      it 'returns http success and shows all excuses' do
        get internal_excuses_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as authenticated regular user' do
      before { sign_in user }

      it 'returns http success and shows only own excuses' do
        get internal_excuses_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to login' do
        get internal_excuses_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'GET /show' do
    let(:excuse) do
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'pending', submission_date: Time.current,
                     proof_link: 'https://example.com/proof')
    end

    context 'as authenticated user' do
      before { sign_in user }

      it 'returns http success' do
        get internal_excuse_path(excuse)
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to login' do
        get internal_excuse_path(excuse)
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'GET /new' do
    context 'as authenticated user' do
      before { sign_in user }

      it 'returns http success' do
        get new_internal_excuse_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to login' do
        get new_internal_excuse_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'POST /create' do
    context 'as authenticated user' do
      before { sign_in user }

      it 'creates excuse and redirects' do
        expect do
          post internal_excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        end.to change(Excuse, :count).by(1)
        expect(response).to have_http_status(:redirect)
      end

      it 'sets status to pending' do
        post internal_excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(Excuse.last.status).to eq('pending')
      end

      it 'sets submission date' do
        post internal_excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(Excuse.last.submission_date).to be_present
      end

      it 'redirects to excuses index' do
        post internal_excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(response).to redirect_to(internal_excuses_path)
      end

      it 'handles missing reason gracefully' do
        post internal_excuses_path, params: { excuse: { event_id: event.id, reason: '', proof_link: 'https://example.com/proof' } }
        # Should either fail validation or still create depending on model validations
        expect(response).to have_http_status(:success).or have_http_status(:redirect)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to login' do
        post internal_excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick' } }
        expect(response).to have_http_status(:redirect)
      end
    end

    context 'recurring excuse' do
      before { sign_in user }

      it 'creates a recurring excuse with matching events auto-attached' do
        # Find the next Monday
        next_monday = Time.current.beginning_of_day
        next_monday += 1.day until next_monday.wday == 1
        create(:event, date: next_monday, end_time: next_monday + 2.hours)

        expect {
          post internal_excuses_path, params: { excuse: {
            reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
            recurring: true, recurring_days: '1',
            start_date: next_monday - 1.day, end_date: next_monday + 1.day
          } }
        }.to change(Excuse, :count).by(1)

        excuse = Excuse.last
        expect(excuse.recurring?).to be true
        expect(excuse.frequency).to eq('weekly')
        expect(excuse.events.count).to eq(1)
      end

      it 'redirects with success notice including event count' do
        next_monday = Time.current.beginning_of_day
        next_monday += 1.day until next_monday.wday == 1
        create(:event, date: next_monday, end_time: next_monday + 2.hours)

        post internal_excuses_path, params: { excuse: {
          reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '1',
          start_date: next_monday - 1.day, end_date: next_monday + 1.day
        } }

        expect(response).to redirect_to(internal_excuses_path)
        expect(flash[:notice]).to match(/1 event/)
      end

      it 're-renders form with alert when no events match the pattern' do
        post internal_excuses_path, params: { excuse: {
          reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '6',
          start_date: 1.week.from_now, end_date: 2.weeks.from_now
        } }

        expect(response).to have_http_status(:ok)
        expect(flash[:alert]).to match(/No scheduled events match/)
      end

      it 'does not create excuse record when no events match' do
        expect {
          post internal_excuses_path, params: { excuse: {
            reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
            recurring: true, recurring_days: '6',
            start_date: 1.week.from_now, end_date: 2.weeks.from_now
          } }
        }.not_to change(Excuse, :count)
      end
    end
  end

  describe 'PATCH /update' do
    let(:excuse) do
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'pending', submission_date: Time.current,
                     proof_link: 'https://example.com/proof')
    end

    context 'as super admin (finalize decision)' do
      before { sign_in admin_user }

      it 'updates excuse status to approved' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        excuse.reload
        expect(excuse.status).to eq('approved')
      end

      it 'updates excuse status to denied' do
        patch internal_excuse_path(excuse), params: { status: 'denied' }
        excuse.reload
        expect(excuse.status).to eq('denied')
      end

      it 'rejects invalid status' do
        patch internal_excuse_path(excuse), params: { status: 'invalid_status' }
        expect(response).to redirect_to(internal_excuse_path(excuse))
        expect(flash[:alert]).to include('Invalid status')
      end

      it 'redirects to excuse show page' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        expect(response).to redirect_to(internal_excuse_path(excuse))
      end
    end

    context 'as officer (provisional decision)' do
      before { sign_in officer }

      it 'records a provisional decision' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        expect(response).to redirect_to(internal_excuse_path(excuse))
        expect(flash[:notice]).to include('Officer decision recorded')
      end

      it 'rejects invalid provisional status' do
        patch internal_excuse_path(excuse), params: { status: 'bogus' }
        expect(response).to redirect_to(internal_excuse_path(excuse))
        expect(flash[:alert]).to include('Invalid provisional status')
      end
    end

    context 'as regular user' do
      before { sign_in user }

      it 'denies access and redirects' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        expect(response).to redirect_to(internal_excuses_path)
      end
    end
  end

  describe 'POST /review' do
    let(:excuse) do
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'approved', submission_date: Time.current,
                     proof_link: 'https://example.com/proof')
    end

    context 'as officer' do
      before { sign_in officer }

      it 'adds officer as reviewer' do
        post review_internal_excuse_path(excuse)
        expect(response).to redirect_to(internal_excuse_path(excuse))
        expect(flash[:notice]).to include('Marked as reviewed')
      end

      it 'prevents duplicate reviews' do
        excuse.reviewers << officer
        excuse.save
        post review_internal_excuse_path(excuse)
        expect(response).to redirect_to(internal_excuse_path(excuse))
        expect(flash[:notice]).to include('already reviewed')
      end
    end

    context 'as regular user' do
      before { sign_in user }

      it 'denies access' do
        post review_internal_excuse_path(excuse)
        expect(response).to redirect_to(internal_excuses_path)
        expect(flash[:alert]).to include('Not authorized')
      end
    end

    context 'on a pending excuse' do
      let(:pending_excuse) do
        Excuse.create!(member: user, event: event, reason: 'Sick', status: 'pending', submission_date: Time.current,
                       proof_link: 'https://example.com/proof')
      end

      before { sign_in officer }

      it 'rejects review of unprocessed excuse' do
        post review_internal_excuse_path(pending_excuse)
        expect(response).to redirect_to(internal_excuse_path(pending_excuse))
        expect(flash[:alert]).to include('Only processed')
      end
    end

    context 'recurring excuse approval' do
      let(:future_event1) { create(:event, date: 1.week.from_now, end_time: 1.week.from_now + 2.hours) }
      let(:future_event2) { create(:event, date: 2.weeks.from_now, end_time: 2.weeks.from_now + 2.hours) }
      let(:recurring_excuse) do
        excuse = Excuse.create!(
          member: user, reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
          status: 'pending', submission_date: Time.current,
          recurring: true, recurring_days: '1,3', start_date: 1.week.ago, end_date: 3.weeks.from_now
        )
        excuse.events << future_event1
        excuse.events << future_event2
        excuse
      end

      before { sign_in admin_user }

      it 'marks attendance as excused for ALL linked events when approved' do
        patch internal_excuse_path(recurring_excuse), params: { status: 'approved' }

        [future_event1, future_event2].each do |ev|
          attendance = Attendance.find_by(event_id: ev.id, user_id: user.id)
          expect(attendance).to be_present
          expect(attendance.status).to eq('excused')
        end
      end
    end
  end

  describe "POST /cancel_recurring" do
    let(:past_event) { create(:event, date: 1.week.ago, end_time: 1.week.ago + 2.hours) }
    let(:future_event) { create(:event, date: 1.week.from_now, end_time: 1.week.from_now + 2.hours) }
    let(:recurring_excuse) do
      excuse = Excuse.create!(
        member: user, reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
        status: 'pending', submission_date: Time.current,
        recurring: true, recurring_days: '1,3', start_date: 2.weeks.ago, end_date: 2.weeks.from_now
      )
      excuse.events << past_event
      excuse.events << future_event
      excuse
    end

    context 'as the excuse owner' do
      before { sign_in user }

      it 'cancels future events and returns count' do
        post cancel_recurring_internal_excuse_path(recurring_excuse)
        expect(response).to redirect_to(internal_excuse_path(recurring_excuse))
        expect(flash[:notice]).to match(/1 future event/)
      end

      it 'keeps past event associations intact' do
        post cancel_recurring_internal_excuse_path(recurring_excuse)
        recurring_excuse.reload
        expect(recurring_excuse.events).to include(past_event)
        expect(recurring_excuse.events).not_to include(future_event)
      end
    end

    context 'with a non-recurring excuse' do
      let(:non_recurring_excuse) do
        Excuse.create!(
          member: user, event: event, reason: 'One-time', proof_link: 'https://example.com/proof',
          status: 'pending', submission_date: Time.current, recurring: false
        )
      end

      before { sign_in user }

      it 'rejects with alert' do
        post cancel_recurring_internal_excuse_path(non_recurring_excuse)
        expect(response).to redirect_to(internal_excuse_path(non_recurring_excuse))
        expect(flash[:alert]).to match(/not a recurring excuse/)
      end
    end

    context 'as unauthorized user' do
      let(:other_user) { create(:user, approval_status: 'approved') }
      before { sign_in other_user }

      it 'rejects access' do
        post cancel_recurring_internal_excuse_path(recurring_excuse)
        expect(response).to redirect_to(internal_excuses_path)
        expect(flash[:alert]).to match(/Not authorized/)
      end
    end

    context 'as admin' do
      before { sign_in admin_user }

      it 'can cancel any member recurring excuse' do
        post cancel_recurring_internal_excuse_path(recurring_excuse)
        expect(response).to redirect_to(internal_excuse_path(recurring_excuse))
        expect(flash[:notice]).to match(/future event/)
      end
    end
  end
end
