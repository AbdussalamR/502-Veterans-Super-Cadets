# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Registrations', type: :request do
  let(:admin) { create(:user, :officer) }
  let(:rejected_user) { create(:user, :pending) }
  let(:approved_user) { create(:user) }

  before do
    # First reject the user
    rejected_user.reject!(rejected_by: admin)
  end

  describe 'GET /admin/registrations (search functionality)' do
    let(:pending_user1) { create(:user, :pending, full_name: 'Alice Johnson', email: 'alice@example.com') }
    let(:pending_user2) { create(:user, :pending, full_name: 'Bob Smith', email: 'bob@test.com') }
    let(:approved_user1) { create(:user, full_name: 'Charlie Brown', email: 'charlie@example.com') }
    let(:rejected_user1) { create(:user, :pending, full_name: 'Diana Prince', email: 'diana@test.com') }

    before do
      # Create users and reject one
      pending_user1
      pending_user2
      approved_user1
      rejected_user1.reject!(rejected_by: admin)
    end

    context 'when user is an admin' do
      before { sign_in admin }

      it 'displays all registrations by default' do
        get admin_registrations_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).to include('Bob Smith')
        expect(response.body).to include('Charlie Brown')
        expect(response.body).to include('Diana Prince')
      end

      it 'searches registrations by name' do
        get admin_registrations_path, params: { search: 'Alice' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Alice Johnson')
        expect(response.body).not_to include('Bob Smith')
        expect(response.body).not_to include('Charlie Brown')
        expect(response.body).not_to include('Diana Prince')
      end

      it 'searches registrations by email' do
        get admin_registrations_path, params: { search: 'bob@test' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Bob Smith')
        expect(response.body).not_to include('Alice Johnson')
        expect(response.body).not_to include('Charlie Brown')
        expect(response.body).not_to include('Diana Prince')
      end

      it 'performs case-insensitive search' do
        get admin_registrations_path, params: { search: 'CHARLIE' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Charlie Brown')
        expect(response.body).not_to include('Alice Johnson')
        expect(response.body).not_to include('Bob Smith')
        expect(response.body).not_to include('Diana Prince')
      end

      it 'shows search results info when searching' do
        get admin_registrations_path, params: { search: 'Alice' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Showing registrations matching "Alice"')
      end

      it 'preserves search parameter in the form' do
        get admin_registrations_path, params: { search: 'Alice' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('value="Alice"')
      end
    end

    context 'when user is not an admin' do
      let(:regular_user) { create(:user) }
      before { sign_in regular_user }

      it 'denies access' do
        get admin_registrations_path
        expect(response).to redirect_to(internal_events_path)
        expect(flash[:alert]).to include('You are not authorized')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get admin_registrations_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'DELETE /admin/registrations/:id/destroy_rejected' do
    context 'when user is an admin' do
      before { sign_in admin }

      it 'allows deletion of rejected users' do
        user = rejected_user
        expect do
          delete destroy_rejected_admin_registration_path(user)
        end.to change(User, :count).by(-1)

        expect(response).to redirect_to(admin_registrations_path)
        expect(flash[:notice]).to include('has been permanently deleted')
      end

      it 'prevents deletion of non-rejected users' do
        user = approved_user
        expect do
          delete destroy_rejected_admin_registration_path(user)
        end.not_to change(User, :count)

        expect(response).to redirect_to(admin_registrations_path)
        expect(flash[:alert]).to include('Only rejected users can be permanently deleted')
      end
    end

    context 'when user is not an admin' do
      let(:regular_user) { create(:user) }
      before { sign_in regular_user }

      it 'denies access' do
        delete destroy_rejected_admin_registration_path(rejected_user)
        expect(response).to redirect_to(internal_events_path)
        expect(flash[:alert]).to include('You are not authorized')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete destroy_rejected_admin_registration_path(rejected_user)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'PATCH notification delivery' do
    before { sign_in admin }

    it 'enqueues a notification when approving a user' do
      pending_user = create(:user, :pending)

      expect do
        patch approve_admin_registration_path(pending_user)
      end.to have_enqueued_job(Notifications::DeliverNotificationJob)
    end

    it 'enqueues a notification when rejecting a user' do
      pending_user = create(:user, :pending)

      expect do
        patch reject_admin_registration_path(pending_user)
      end.to have_enqueued_job(Notifications::DeliverNotificationJob)
    end
  end
end
