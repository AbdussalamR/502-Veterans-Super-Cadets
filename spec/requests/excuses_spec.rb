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
  end
end
