# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::AuditionSessions', type: :request do
  let(:admin) { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  let!(:audition_session) { create(:audition_session) }
  let(:valid_params) do
    {
      audition_session: {
        label: "Fall 2026",
        start_datetime: 1.week.from_now,
        end_datetime: 1.week.from_now + 3.hours,
        location: "Music Activities Center (MAC)"
      }
    }
  end

  describe 'GET /admin/audition_sessions' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'renders successfully' do
        get admin_audition_sessions_path
        expect(response).to have_http_status(:success)
      end

      it 'displays existing audition sessions' do
        get admin_audition_sessions_path
        expect(response.body).to include(audition_session.label)
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'redirects away' do
        get admin_audition_sessions_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('You are not authorized')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get admin_audition_sessions_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'GET /admin/audition_sessions/new' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'renders successfully' do
        get new_admin_audition_session_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'redirects away' do
        get new_admin_audition_session_path
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'POST /admin/audition_sessions' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'creates an audition session with valid params' do
        expect do
          post admin_audition_sessions_path, params: valid_params
        end.to change(AuditionSession, :count).by(1)
        expect(response).to redirect_to(admin_website_path(tab: 'auditions'))
      end

      it 'does not create when end is before start' do
        expect do
          post admin_audition_sessions_path, params: {
            audition_session: {
              label: "Bad Session",
              start_datetime: 1.week.from_now,
              end_datetime: 1.day.from_now,
              location: "MAC"
            }
          }
        end.not_to change(AuditionSession, :count)
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'does not create and redirects away' do
        expect do
          post admin_audition_sessions_path, params: valid_params
        end.not_to change(AuditionSession, :count)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not authenticated' do
      it 'does not create and redirects to sign in' do
        expect do
          post admin_audition_sessions_path, params: valid_params
        end.not_to change(AuditionSession, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'GET /admin/audition_sessions/:id/edit' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'renders successfully' do
        get edit_admin_audition_session_path(audition_session)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'redirects away' do
        get edit_admin_audition_session_path(audition_session)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin/audition_sessions/:id' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'updates the audition session' do
        patch admin_audition_session_path(audition_session), params: {
          audition_session: { label: "Updated Label" }
        }
        expect(audition_session.reload.label).to eq("Updated Label")
        expect(response).to redirect_to(admin_website_path(tab: 'auditions'))
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'does not update and redirects away' do
        patch admin_audition_session_path(audition_session), params: {
          audition_session: { label: "Updated Label" }
        }
        expect(audition_session.reload.label).not_to eq("Updated Label")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'DELETE /admin/audition_sessions/:id' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'deletes the audition session' do
        expect do
          delete admin_audition_session_path(audition_session)
        end.to change(AuditionSession, :count).by(-1)
        expect(response).to redirect_to(admin_website_path(tab: 'auditions'))
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'does not delete and redirects away' do
        expect do
          delete admin_audition_session_path(audition_session)
        end.not_to change(AuditionSession, :count)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when user is not authenticated' do
      it 'does not delete and redirects to sign in' do
        expect do
          delete admin_audition_session_path(audition_session)
        end.not_to change(AuditionSession, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end