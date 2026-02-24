# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Excuses", type: :request do
  let(:user) { create(:user, approval_status: 'approved') }
  let(:admin_user) { create(:user, :super_admin) }
  let(:event) { create(:event) }

  describe "GET /index" do
    context 'as authenticated user' do
      before { sign_in user }

      it "returns http success" do
        get excuses_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user' do
      it "redirects to login" do
        get excuses_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /show" do
    let(:excuse) {
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'pending', submission_date: Time.current, 
                     proof_link: 'https://example.com/proof')
    }

    context 'as authenticated user' do
      before { sign_in user }

      it "returns http success" do
        get excuse_path(excuse)
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user' do
      it "redirects to login" do
        get excuse_path(excuse)
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "GET /new" do
    context 'as authenticated user' do
      before { sign_in user }

      it "returns http success" do
        get new_excuse_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user' do
      it "redirects to login" do
        get new_excuse_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "POST /create" do
    context 'as authenticated user' do
      before { sign_in user }

      it "creates excuse and redirects" do
        expect {
          post excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        }.to change(Excuse, :count).by(1)
        expect(response).to have_http_status(:redirect)
      end

      it "sets status to pending" do
        post excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(Excuse.last.status).to eq('pending')
      end

      it "sets submission date" do
        post excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(Excuse.last.submission_date).to be_present
      end

      it "redirects to excuses index" do
        post excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick', proof_link: 'https://example.com/proof' } }
        expect(response).to redirect_to(excuses_path)
      end
    end

    context 'as unauthenticated user' do
      it "redirects to login" do
        post excuses_path, params: { excuse: { event_id: event.id, reason: 'Sick' } }
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "PATCH /update" do
    let(:excuse) {
      Excuse.create!(member: user, event: event, reason: 'Sick', status: 'pending', submission_date: Time.current, 
                     proof_link: 'https://example.com/proof')
    }

    context 'as admin user' do
      before { sign_in admin_user }

      it "updates excuse status to approved" do
        patch excuse_path(excuse), params: { status: 'approved' }
        excuse.reload
        expect(excuse.status).to eq('approved')
      end

      it "updates excuse status to denied" do
        patch excuse_path(excuse), params: { status: 'denied' }
        excuse.reload
        expect(excuse.status).to eq('denied')
      end

      it "sets reviewed_by to current user" do
        patch excuse_path(excuse), params: { status: 'approved' }
        excuse.reload
        expect(excuse.reviewed_by).to eq(admin_user)
      end

      it "sets reviewed_date" do
        patch excuse_path(excuse), params: { status: 'approved' }
        excuse.reload
        expect(excuse.reviewed_date).to be_present
      end

      it "redirects to excuse show page" do
        patch excuse_path(excuse), params: { status: 'approved' }
        expect(response).to redirect_to(excuse_path(excuse))
      end
    end

    context 'as regular user' do
      before { sign_in user }

      it "denies access and redirects" do
        patch excuse_path(excuse), params: { status: 'approved' }
        expect(response).to redirect_to(excuses_path)
      end
    end
  end
end
