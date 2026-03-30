# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::PerformanceRequests', type: :request do
  let(:director)     { create(:user, :super_admin) }
  let(:officer)      { create(:user, :officer) }
  let(:regular_user) { create(:user) }
  let!(:request_pending)  { create(:performance_request, name: 'Pending Org', status: 'pending') }
  let!(:request_reviewed) { create(:performance_request, name: 'Reviewed Org', status: 'reviewed') }

  # ─── Index ────────────────────────────────────────────────────────────────────

  describe 'GET /internal/performance_requests' do
    context 'as a director' do
      before { sign_in director }

      it 'returns http success' do
        get internal_performance_requests_path
        expect(response).to have_http_status(:success)
      end

      it 'lists all performance requests' do
        get internal_performance_requests_path
        expect(response.body).to include('Pending Org')
        expect(response.body).to include('Reviewed Org')
      end
    end

    context 'as an officer' do
      before { sign_in officer }

      it 'redirects away (director only)' do
        get internal_performance_requests_path
        expect(response).to redirect_to(internal_events_path)
      end
    end

    context 'as a regular user' do
      before { sign_in regular_user }

      it 'redirects away' do
        get internal_performance_requests_path
        expect(response).to redirect_to(internal_events_path)
      end
    end

    context 'as unauthenticated' do
      it 'redirects to sign-in' do
        get internal_performance_requests_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  # ─── Show ─────────────────────────────────────────────────────────────────────

  describe 'GET /internal/performance_requests/:id' do
    context 'as a director' do
      before { sign_in director }

      it 'returns http success' do
        get internal_performance_request_path(request_pending)
        expect(response).to have_http_status(:success)
      end

      it 'shows the requester details' do
        get internal_performance_request_path(request_pending)
        expect(response.body).to include('Pending Org')
      end
    end

    context 'as an officer' do
      before { sign_in officer }

      it 'redirects away' do
        get internal_performance_request_path(request_pending)
        expect(response).to redirect_to(internal_events_path)
      end
    end
  end

  # ─── Update (status change) ───────────────────────────────────────────────────

  describe 'PATCH /internal/performance_requests/:id' do
    context 'as a director' do
      before { sign_in director }

      it 'marks a pending request as reviewed' do
        patch internal_performance_request_path(request_pending), params: { status: 'reviewed' }
        expect(request_pending.reload.status).to eq('reviewed')
        expect(response).to redirect_to(internal_performance_requests_path)
        expect(flash[:notice]).to include('approved')
      end

      it 'resets a reviewed request back to pending' do
        patch internal_performance_request_path(request_reviewed), params: { status: 'pending' }
        expect(request_reviewed.reload.status).to eq('pending')
        expect(flash[:notice]).to include('reset to pending')
      end

      it 'rejects an invalid status' do
        patch internal_performance_request_path(request_pending), params: { status: 'approved' }
        expect(request_pending.reload.status).to eq('pending')
        expect(response).to redirect_to(internal_performance_request_path(request_pending))
        expect(flash[:alert]).to include('Invalid status')
      end
    end

    context 'as an officer' do
      before { sign_in officer }

      it 'redirects away without changing the status' do
        patch internal_performance_request_path(request_pending), params: { status: 'reviewed' }
        expect(request_pending.reload.status).to eq('pending')
        expect(response).to redirect_to(internal_events_path)
      end
    end

    context 'as a regular user' do
      before { sign_in regular_user }

      it 'redirects away' do
        patch internal_performance_request_path(request_pending), params: { status: 'reviewed' }
        expect(response).to redirect_to(internal_events_path)
      end
    end
  end
end
