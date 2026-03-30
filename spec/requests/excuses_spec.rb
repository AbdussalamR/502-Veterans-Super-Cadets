# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Excuses', type: :request do
  let(:section_tenor) { create(:section, name: "Tenor 1") }
  let(:section_bass) { create(:section, name: "Bass 2") }
  
  let(:user) { create(:user, approval_status: 'approved', section: section_tenor) }
  let(:officer_tenor) { create(:user, :officer, section: section_tenor) }
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

    # --- NEW: Story A3 AC 2 (Section Filtering) ---
    context 'as a Section Leader (Officer)' do
      let(:member_tenor) { create(:user, section: section_tenor, full_name: "Tenor Member") }
      let(:member_bass) { create(:user, section: section_bass, full_name: "Bass Member") }
      let!(:excuse_tenor) { create(:excuse, member: member_tenor) }
      let!(:excuse_bass) { create(:excuse, member: member_bass) }

      before { sign_in officer_tenor }

      it 'shows excuses only for members in their own section' do
        get internal_excuses_path
        expect(response.body).to include("Tenor Member")
        expect(response.body).not_to include("Bass Member")
      end
    end
  end

  describe 'GET /show' do
    let(:excuse) do
      Excuse.create!(member: user, events: [event], reason: 'Sick', 
                     status: 'Pending Section Leader Review', submission_date: Time.current,
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

    # --- NEW: Story A3 AC 3 (Rainy Day - 403 Forbidden) ---
    context 'as an Officer viewing a different section' do
      let(:member_bass) { create(:user, section: section_bass) }
      let(:excuse_bass) { create(:excuse, member: member_bass) }
      
      before { sign_in officer_tenor }

      it 'returns 403 Forbidden when accessing an excuse ID from another section via URL' do
        get internal_excuse_path(excuse_bass)
        expect(response.status).to eq(403)
        expect(response.body).to include("403 Forbidden")
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
  end

  describe 'POST /create' do
    context 'as authenticated user' do
      before { sign_in user }

      it 'creates excuse and redirects' do
        expect do
          post internal_excuses_path, params: { excuse: { event_ids: [event.id], reason: 'Sick', proof_link: 'https://example.com/proof' } }
        end.to change(Excuse, :count).by(1)
        expect(response).to have_http_status(:redirect)
      end

      it 'enqueues a review notification for section officers' do
        officer_tenor

        expect do
          post internal_excuses_path, params: { excuse: { event_ids: [event.id], reason: 'Sick', proof_link: 'https://example.com/proof' } }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end

      it 'targets section officers for a normal excuse submission' do
        officer_tenor
        admin_user

        post internal_excuses_path, params: { excuse: { event_ids: [event.id], reason: 'Sick', proof_link: 'https://example.com/proof' } }

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
          job[:job] == Notifications::DeliverNotificationJob
        end

        expect(jobs.map { |job| job[:args][0] }).to include('excuse_submitted_for_review')
        expect(jobs.map { |job| job[:args][1] }).to include(officer_tenor.id)
        expect(jobs.map { |job| job[:args][1] }).not_to include(admin_user.id)
      end

      it 'targets directors for a personal excuse submission' do
        officer_tenor
        admin_user

        post internal_excuses_path, params: { excuse: { event_ids: [event.id], reason: 'Sensitive matter', proof_link: 'https://example.com/proof', is_personal: '1' } }

        jobs = ActiveJob::Base.queue_adapter.enqueued_jobs.select do |job|
          job[:job] == Notifications::DeliverNotificationJob
        end

        expect(jobs.map { |job| job[:args][0] }).to include('excuse_submitted_for_director_review')
        expect(jobs.map { |job| job[:args][1] }).to include(admin_user.id)
        expect(jobs.map { |job| job[:args][1] }).not_to include(officer_tenor.id)
      end

      # --- NEW: Story A3 AC 1 (Default Status) ---
      it 'sets status to "Pending Section Leader Review"' do
        post internal_excuses_path, params: { excuse: { event_ids: [event.id], reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(Excuse.last.status).to eq('Pending Section Leader Review')
      end

      it 'sets submission date' do
        post internal_excuses_path, params: { excuse: { event_ids: [event.id], reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(Excuse.last.submission_date).to be_present
      end
    end

    context 'recurring excuse' do
      before { sign_in user }

      let(:next_monday) do
        t = Time.current.beginning_of_day
        t += 1.day until t.wday == 1
        t
      end

      it 'creates a recurring excuse with matching events auto-attached' do
        create(:event, date: next_monday.change(hour: 11), end_time: next_monday.change(hour: 12))

        expect {
          post internal_excuses_path, params: { excuse: {
            reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
            recurring: true, recurring_days: '1',
            start_date: next_monday - 1.day, end_date: next_monday + 1.day,
            recurring_start_time: '10:30', recurring_end_time: '12:00'
          } }
        }.to change(Excuse, :count).by(1)

        excuse = Excuse.last
        expect(excuse.recurring?).to be true
        expect(excuse.events.count).to eq(1)
      end

      it 'does not attach events outside the specified time window' do
        create(:event, date: next_monday.change(hour: 14), end_time: next_monday.change(hour: 15))

        post internal_excuses_path, params: { excuse: {
          reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
          recurring: true, recurring_days: '1',
          start_date: next_monday - 1.day, end_date: next_monday + 1.day,
          recurring_start_time: '10:30', recurring_end_time: '12:00'
        } }

        expect(Excuse.last.events.count).to eq(0)
      end

      it 'fails validation without time fields' do
        expect {
          post internal_excuses_path, params: { excuse: {
            reason: 'Weekly conflict', proof_link: 'https://example.com/proof',
            recurring: true, recurring_days: '1',
            start_date: next_monday - 1.day, end_date: next_monday + 1.day
          } }
        }.not_to change(Excuse, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe 'PATCH /update' do
    let(:excuse) do
      Excuse.create!(member: user, events: [event], reason: 'Sick', status: 'Pending Section Leader Review', 
                     submission_date: Time.current, proof_link: 'https://example.com/proof')
    end

    context 'as super admin (Director Finalization - AC 5)' do
      before { sign_in admin_user }

      it 'finalizes excuse status and overrides provisional decisions' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        excuse.reload
        expect(excuse.status).to eq('approved')
        expect(flash[:notice]).to include('approved')
      end

      it 'syncs attendance automatically on finalize' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        attendance = Attendance.find_by(user: user, event: event)
        expect(attendance.status).to eq('excused')
      end

      it 'enqueues a member notification on final decision' do
        expect do
          patch internal_excuse_path(excuse), params: { status: 'approved' }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'as officer (Section Leader Provisional Decision - AC 2)' do
      before { sign_in officer_tenor }

      it 'records a provisional decision and moves top-level status to pending' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        excuse.reload
        expect(excuse.officer_status).to eq('approved')
        expect(excuse.status).to eq('pending') # Now awaiting Director
        expect(flash[:notice]).to include('Officer decision recorded')
      end

      it 'enqueues a director review notification' do
        create(:user, :super_admin)

        expect do
          patch internal_excuse_path(excuse), params: { status: 'approved' }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'as regular user' do
      before { sign_in user }

      it 'denies access (403)' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        expect(response.status).to eq(403)
      end
    end

    context 'as officer from a different section (AC 3)' do
      let(:officer_bass) { create(:user, :officer, section: section_bass) }
      before { sign_in officer_bass }

      it 'returns 403 Forbidden' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        expect(response.status).to eq(403)
      end
    end

    context 'as officer provisionally denying (AC 2)' do
      before { sign_in officer_tenor }

      it 'records a provisional denial and moves status to pending' do
        patch internal_excuse_path(excuse), params: { status: 'denied' }
        excuse.reload
        expect(excuse.officer_status).to eq('denied')
        expect(excuse.status).to eq('pending')
      end
    end

    context 'as super admin denying (AC 5)' do
      before { sign_in admin_user }

      it 'finalizes excuse as denied' do
        patch internal_excuse_path(excuse), params: { status: 'denied' }
        excuse.reload
        expect(excuse.status).to eq('denied')
      end
    end
  end

  describe 'POST /review' do
    let(:excuse) do
      Excuse.create!(member: user, events: [event], reason: 'Sick', status: 'approved', 
                     submission_date: Time.current, proof_link: 'https://example.com/proof')
    end

    context 'as officer' do
      before { sign_in officer_tenor }

      it 'adds officer as reviewer' do
        post review_internal_excuse_path(excuse)
        expect(response).to redirect_to(internal_excuse_path(excuse))
        expect(flash[:notice]).to include('Marked as reviewed')
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
        recurring: true, recurring_days: '1,3', start_date: 2.weeks.ago, end_date: 2.weeks.from_now,
        recurring_start_time: Time.zone.parse('08:00'), recurring_end_time: Time.zone.parse('23:59')
      )
      excuse.events << past_event
      excuse.events << future_event
      excuse
    end

    context 'as the excuse owner' do
      before { sign_in user }

      it 'cancels future events and keeps past event associations' do
        post cancel_recurring_internal_excuse_path(recurring_excuse)
        recurring_excuse.reload
        expect(recurring_excuse.events).to include(past_event)
        expect(recurring_excuse.events).not_to include(future_event)
      end
    end

    context 'as unauthorized officer (wrong section)' do
      let(:officer_bass) { create(:user, :officer, section: section_bass) }
      before { sign_in officer_bass }

      it 'returns 403 Forbidden' do
        post cancel_recurring_internal_excuse_path(recurring_excuse)
        expect(response.status).to eq(403)
      end
    end
  end

  describe 'section access for officers without a section assigned' do
    let(:unassigned_member) { create(:user, approval_status: 'approved', section: nil) }
    let(:unassigned_officer) { create(:user, :officer, section: nil) }
    let(:excuse_from_unassigned) do
      Excuse.create!(
        member: unassigned_member, reason: 'Sick', proof_link: 'https://example.com/proof',
        status: 'Pending Section Leader Review', submission_date: Time.current
      )
    end

    context 'as an officer with no section viewing an unassigned member excuse' do
      before { sign_in unassigned_officer }

      it 'allows access (nil == nil)' do
        get internal_excuse_path(excuse_from_unassigned)
        expect(response).to have_http_status(:success)
      end

      it 'shows the unassigned member excuse in the index' do
        excuse_from_unassigned
        get internal_excuses_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include(unassigned_member.full_name)
      end
    end

    context 'as an officer with no section viewing a section member excuse' do
      let(:excuse_from_section_member) do
        Excuse.create!(
          member: user, reason: 'Sick', proof_link: 'https://example.com/proof',
          status: 'Pending Section Leader Review', submission_date: Time.current
        )
      end
      before { sign_in unassigned_officer }

      it 'returns 403 Forbidden' do
        get internal_excuse_path(excuse_from_section_member)
        expect(response.status).to eq(403)
      end
    end

    context 'as a section officer viewing an unassigned member excuse' do
      before { sign_in officer_tenor }

      it 'returns 403 Forbidden' do
        get internal_excuse_path(excuse_from_unassigned)
        expect(response.status).to eq(403)
      end
    end
  end
end
