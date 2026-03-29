# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Demerits', type: :request do
  let(:shared_section) { create(:section) }
  let(:super_admin) { create(:user, :super_admin) }
  let(:officer) { create(:user, :officer, section: shared_section) }
  let(:regular_user) { create(:user) }
  let(:member) { create(:user, section: shared_section) }

  let(:valid_demerit_attributes) do
    {
      member_id: member.id,
      value: 1,
      reason: 'Late to rehearsal',
      date: Time.current.to_s
    }
  end

  let(:invalid_demerit_attributes) do
    {
      member_id: member.id,
      value: nil,
      reason: '',
      date: ''
    }
  end

  # ── INDEX ──────────────────────────────────────────────────

  describe 'GET /internal/demerits (index)' do
    context 'as officer (sunny day)' do
      before { sign_in officer }

      it 'renders the demerits index successfully' do
        get internal_demerits_path
        expect(response).to have_http_status(:success)
      end

      it 'displays existing demerits' do
        Demerit.create!(member: member, given_by: officer, value: 2, reason: 'Late', date: Time.current)
        get internal_demerits_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Late')
      end
    end

    context 'as super admin' do
      before { sign_in super_admin }

      it 'renders the demerits index successfully' do
        get internal_demerits_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as regular user (rainy day)' do
      before { sign_in regular_user }

      it 'denies access' do
        get internal_demerits_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('admin or officer')
      end
    end

    context 'as unauthenticated user (rainy day)' do
      it 'redirects to sign in' do
        get internal_demerits_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  # ── SHOW ───────────────────────────────────────────────────

  describe 'GET /internal/demerits/:id (show)' do
    let(:demerit) { Demerit.create!(member: member, given_by: officer, value: 1, reason: 'Tardy', date: Time.current) }

    context 'as the member who received the demerit' do
      before { sign_in member }

      it 'allows viewing own demerit' do
        get internal_demerit_path(demerit)
        expect(response).to have_http_status(:success)
      end
    end

    context 'as officer' do
      before { sign_in officer }

      it 'allows viewing any demerit' do
        get internal_demerit_path(demerit)
        expect(response).to have_http_status(:success)
      end
    end

    context 'as another regular user (rainy day)' do
      let(:other_user) { create(:user) }
      before { sign_in other_user }

      it 'denies access to demerit belonging to someone else' do
        get internal_demerit_path(demerit)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('not authorized')
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to sign in' do
        get internal_demerit_path(demerit)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  # ── NEW ────────────────────────────────────────────────────

  describe 'GET /internal/users/:member_id/demerits/new' do
    context 'as officer (sunny day)' do
      before { sign_in officer }

      it 'renders the new demerit form for a specific member' do
        get internal_new_member_demerit_path(member_id: member.id)
        expect(response).to have_http_status(:success)
      end
    end

    context 'as regular user (rainy day)' do
      before { sign_in regular_user }

      it 'denies access' do
        get internal_new_member_demerit_path(member_id: member.id)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('admin or officer')
      end
    end
  end

  # ── CREATE ─────────────────────────────────────────────────

  describe 'POST /internal/demerits (create)' do
    context 'as officer (sunny day)' do
      before { sign_in officer }

      it 'creates a new demerit' do
        expect do
          post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        end.to change(Demerit, :count).by(1)
      end

      it 'sets given_by to current user' do
        post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        expect(Demerit.last.given_by).to eq(officer)
      end

      it 'redirects to the member profile on success' do
        post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        expect(response).to redirect_to(internal_user_path(member))
      end

      it 'displays success flash message' do
        post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        expect(flash[:success]).to include(member.full_name)
      end

      it 'enqueues a member notification' do
        expect do
          post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'as officer with invalid data (rainy day)' do
      before { sign_in officer }

      it 'does not create a demerit with missing value' do
        expect do
          post internal_demerits_path, params: { demerit: invalid_demerit_attributes }
        end.not_to change(Demerit, :count)
      end

      it 'renders the new form again on failure' do
        post internal_demerits_path, params: { demerit: invalid_demerit_attributes }
        expect(response).to have_http_status(:success)
      end

      it 'rejects demerit with zero value' do
        expect do
          post internal_demerits_path, params: { demerit: valid_demerit_attributes.merge(value: 0) }
        end.not_to change(Demerit, :count)
      end

      it 'rejects demerit with negative value' do
        expect do
          post internal_demerits_path, params: { demerit: valid_demerit_attributes.merge(value: -1) }
        end.not_to change(Demerit, :count)
      end
    end

    context 'as regular user (rainy day)' do
      before { sign_in regular_user }

      it 'denies access' do
        post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        expect(response).to redirect_to(root_path)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to sign in' do
        post internal_demerits_path, params: { demerit: valid_demerit_attributes }
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  # ── EDIT ───────────────────────────────────────────────────

  describe 'GET /internal/demerits/:id/edit' do
    let(:demerit) { Demerit.create!(member: member, given_by: officer, value: 1, reason: 'Late', date: Time.current) }

    context 'as officer' do
      before { sign_in officer }

      it 'renders the edit form' do
        get edit_internal_demerit_path(demerit)
        expect(response).to have_http_status(:success)
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies access' do
        get edit_internal_demerit_path(demerit)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ── UPDATE ─────────────────────────────────────────────────

  describe 'PATCH /internal/demerits/:id (update)' do
    let(:demerit) { Demerit.create!(member: member, given_by: officer, value: 1, reason: 'Late', date: Time.current) }

    context 'as officer (sunny day)' do
      before { sign_in officer }

      it 'updates the demerit reason' do
        patch internal_demerit_path(demerit), params: { demerit: { reason: 'Very late' } }
        demerit.reload
        expect(demerit.reason).to eq('Very late')
      end

      it 'updates the demerit value' do
        patch internal_demerit_path(demerit), params: { demerit: { value: 3 } }
        demerit.reload
        expect(demerit.value).to eq(3)
      end

      it 'redirects to the member profile' do
        patch internal_demerit_path(demerit), params: { demerit: { reason: 'Updated' } }
        expect(response).to redirect_to(internal_user_path(member))
      end

      it 'enqueues a notification when updating a demerit' do
        expect do
          patch internal_demerit_path(demerit), params: { demerit: { reason: 'Updated' } }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'as officer with invalid data (rainy day)' do
      before { sign_in officer }

      it 'does not update with blank reason' do
        patch internal_demerit_path(demerit), params: { demerit: { reason: '' } }
        demerit.reload
        expect(demerit.reason).to eq('Late')
      end
    end

    context 'as regular user' do
      before { sign_in regular_user }

      it 'denies access' do
        patch internal_demerit_path(demerit), params: { demerit: { reason: 'Hacked' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  # ── DESTROY ────────────────────────────────────────────────

  describe 'DELETE /internal/demerits/:id (destroy)' do
    let!(:demerit) { Demerit.create!(member: member, given_by: officer, value: 1, reason: 'Late', date: Time.current) }

    context 'as officer (sunny day)' do
      before { sign_in officer }

      it 'destroys the demerit' do
        expect do
          delete internal_demerit_path(demerit)
        end.to change(Demerit, :count).by(-1)
      end

      it 'redirects to member profile by default' do
        delete internal_demerit_path(demerit)
        expect(response).to redirect_to(internal_user_path(member))
      end

      it 'redirects to demerits index when source is demerits_index' do
        delete internal_demerit_path(demerit), params: { source: 'demerits_index' }
        expect(response).to redirect_to(internal_demerits_path)
      end

      it 'enqueues a notification when deleting a demerit' do
        expect do
          delete internal_demerit_path(demerit)
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'as regular user (rainy day)' do
      before { sign_in regular_user }

      it 'denies access and does not delete' do
        expect do
          delete internal_demerit_path(demerit)
        end.not_to change(Demerit, :count)
        expect(response).to redirect_to(root_path)
      end
    end

    context 'as unauthenticated user' do
      it 'redirects to sign in' do
        expect do
          delete internal_demerit_path(demerit)
        end.not_to change(Demerit, :count)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end
