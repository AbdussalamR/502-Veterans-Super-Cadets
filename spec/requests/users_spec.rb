# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Users', type: :request do
  let(:super_admin) { create(:user, :super_admin) }
  let(:officer) { create(:user, :officer) }
  let(:regular_user) { create(:user) }
  let(:user_to_delete) { create(:user) }

  # Create test users with specific names and emails for search testing
  let(:john_doe) { create(:user, full_name: 'John Doe', email: 'john.doe@example.com') }
  let(:jane_smith) { create(:user, full_name: 'Jane Smith', email: 'jane.smith@example.com') }
  let(:bob_wilson) { create(:user, full_name: 'Bob Wilson', email: 'bob.wilson@test.com') }

  describe 'DELETE /internal/user_management/:id' do
    context 'when user is a super admin' do
      before { sign_in super_admin }

      it 'allows deletion of other users' do
        user = user_to_delete
        expect do
          delete internal_user_path(user)
        end.to change(User, :count).by(-1)

        expect(response).to redirect_to(internal_users_path)
        expect(flash[:notice]).to include('has been permanently deleted')
      end

      it 'prevents deletion of self' do
        expect do
          delete internal_user_path(super_admin)
        end.not_to change(User, :count)

        expect(response).to redirect_to(internal_users_path)
        expect(flash[:alert]).to include('You cannot delete your own account')
      end
    end

    context 'when user is an officer (not super admin)' do
      before { sign_in officer }

      it 'denies access to delete action' do
        delete internal_user_path(user_to_delete)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('You must be a super admin')
      end
    end

    context 'when user is a regular user' do
      before { sign_in regular_user }

      it 'denies access to delete action' do
        delete internal_user_path(user_to_delete)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('You must be an admin')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        delete internal_user_path(user_to_delete)
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'GET /internal/user_management (search functionality)' do
    context 'when user is an admin' do
      before do
        sign_in super_admin
        john_doe
        jane_smith
        bob_wilson
      end

      it 'displays all users by default' do
        get internal_users_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('John Doe')
        expect(response.body).to include('Jane Smith')
        expect(response.body).to include('Bob Wilson')
      end

      it 'searches users by name' do
        get internal_users_path, params: { search: 'John' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
        expect(response.body).not_to include('Bob Wilson')
      end

      it 'searches users by email' do
        get internal_users_path, params: { search: 'jane.smith' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Jane Smith')
        expect(response.body).not_to include('John Doe')
        expect(response.body).not_to include('Bob Wilson')
      end

      it 'performs case-insensitive search' do
        get internal_users_path, params: { search: 'BOB' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Bob Wilson')
        expect(response.body).not_to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
      end

      it 'filters users by role' do
        get internal_users_path, params: { role: 'user' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('John Doe')
        expect(response.body).to include('Jane Smith')
        expect(response.body).to include('Bob Wilson')
      end

      it 'combines search and role filtering' do
        get internal_users_path, params: { search: 'John', role: 'user' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
        expect(response.body).not_to include('Bob Wilson')
      end

      it 'shows no results message when no users match' do
        get internal_users_path, params: { search: 'nonexistent' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('No users found')
        expect(response.body).not_to include('John Doe')
        expect(response.body).not_to include('Jane Smith')
        expect(response.body).not_to include('Bob Wilson')
      end

      it 'preserves search parameters in the form' do
        get internal_users_path, params: { search: 'John', role: 'user' }
        expect(response).to have_http_status(:success)
        expect(response.body).to include('value="John"')
        expect(response.body).to include('selected="selected" value="user">Regular Users</option>')
      end

      it 'handles empty search gracefully' do
        get internal_users_path, params: { search: '' }
        expect(response).to have_http_status(:success)
      end

      it 'handles whitespace-only search gracefully' do
        get internal_users_path, params: { search: '   ' }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not an admin' do
      before { sign_in regular_user }

      it 'denies access to user management' do
        get internal_users_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('You must be an admin')
      end
    end

    context 'when user is not authenticated' do
      it 'redirects to sign in' do
        get internal_users_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end

  describe 'GET /internal/user_management/:id' do
    context 'when viewing own profile' do
      before { sign_in regular_user }

      it 'allows users to view their own profile' do
        get internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when viewing another users profile as admin' do
      before { sign_in super_admin }

      it 'allows admins to view any profile' do
        get internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when viewing another users profile as officer' do
      before { sign_in officer }

      it 'allows officers to view any profile' do
        get internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when viewing another users profile as regular user' do
      let(:other_user) { create(:user) }
      before { sign_in regular_user }

      it 'denies access' do
        get internal_user_path(other_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('not authorized')
      end
    end
  end

  describe 'GET /internal/user_management/:id/edit' do
    context 'when user is admin' do
      before { sign_in super_admin }

      it 'renders the edit form' do
        get edit_internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is editing their own profile' do
      before { sign_in regular_user }

      it 'allows access' do
        get edit_internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is not allowed to edit another profile' do
      let(:other_user) { create(:user) }

      before { sign_in regular_user }

      it 'denies access' do
        get edit_internal_user_path(other_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /internal/user_management/:id' do
    context 'when user is admin' do
      before { sign_in super_admin }

      it 'updates user information' do
        patch internal_user_path(regular_user), params: { user: { full_name: 'Updated Name' } }
        regular_user.reload
        expect(regular_user.full_name).to eq('Updated Name')
        expect(response).to redirect_to(internal_user_path(regular_user))
      end

      it 'renders edit on invalid data' do
        allow_any_instance_of(User).to receive(:update).and_return(false)
        patch internal_user_path(regular_user), params: { user: { full_name: '' } }
        expect(response).to have_http_status(:success)
      end
    end

    context 'when user is updating their own notification settings' do
      before { sign_in regular_user }

      it 'allows the update' do
        patch internal_user_path(regular_user), params: { user: { email_notifications_enabled: '0' } }
        regular_user.reload
        expect(regular_user.email_notifications_enabled).to be false
        expect(response).to redirect_to(internal_user_path(regular_user))
      end
    end

    context 'when user is not allowed to update another profile' do
      let(:other_user) { create(:user) }

      before { sign_in regular_user }

      it 'denies access' do
        patch internal_user_path(other_user), params: { user: { full_name: 'Hacked' } }
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /internal/user_management/:id/promote_to_officer' do
    context 'when user is super admin' do
      before { sign_in super_admin }

      it 'promotes user to officer' do
        patch promote_to_officer_internal_user_path(regular_user)
        regular_user.reload
        expect(regular_user.role).to eq('officer')
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:notice]).to include('promoted to officer')
      end

      it 'enqueues a role notification' do
        expect do
          patch promote_to_officer_internal_user_path(regular_user)
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end

      it 'handles errors gracefully' do
        allow_any_instance_of(User).to receive(:promote_to_officer!).and_raise(StandardError, 'Test error')
        patch promote_to_officer_internal_user_path(regular_user)
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:alert]).to include('Test error')
      end
    end

    context 'when user is not super admin' do
      before { sign_in officer }

      it 'denies access' do
        patch promote_to_officer_internal_user_path(regular_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /internal/user_management/:id/promote_to_super_admin' do
    context 'when user is super admin' do
      before { sign_in super_admin }

      it 'promotes user to super admin' do
        patch promote_to_super_admin_internal_user_path(regular_user)
        regular_user.reload
        expect(regular_user.role).to eq('super_admin')
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:notice]).to include('promoted to super admin')
      end

      it 'handles errors gracefully' do
        allow_any_instance_of(User).to receive(:promote_to_super_admin!).and_raise(StandardError, 'Test error')
        patch promote_to_super_admin_internal_user_path(regular_user)
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:alert]).to include('Test error')
      end
    end

    context 'when user is not super admin' do
      before { sign_in officer }

      it 'denies access' do
        patch promote_to_super_admin_internal_user_path(regular_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /internal/user_management/:id/demote_to_user' do
    context 'when user is super admin' do
      before { sign_in super_admin }

      it 'demotes officer to user' do
        patch demote_to_user_internal_user_path(officer)
        officer.reload
        expect(officer.role).to eq('user')
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:notice]).to include('demoted to user')
      end

      it 'handles errors gracefully' do
        allow_any_instance_of(User).to receive(:demote_to_user!).and_raise(StandardError, 'Test error')
        patch demote_to_user_internal_user_path(officer)
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:alert]).to include('Test error')
      end
    end

    context 'when user is not super admin' do
      before { sign_in officer }

      it 'denies access' do
        patch demote_to_user_internal_user_path(regular_user)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /internal/user_management/:id/demote_to_officer' do
    let(:another_super_admin) { create(:user, :super_admin) }

    context 'when user is super admin' do
      before { sign_in super_admin }

      it 'demotes super admin to officer' do
        patch demote_to_officer_internal_user_path(another_super_admin)
        another_super_admin.reload
        expect(another_super_admin.role).to eq('officer')
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:notice]).to include('demoted to officer')
      end

      it 'handles errors gracefully' do
        allow_any_instance_of(User).to receive(:demote_to_officer!).and_raise(StandardError, 'Test error')
        patch demote_to_officer_internal_user_path(another_super_admin)
        expect(response).to redirect_to(internal_users_path)
        expect(flash[:alert]).to include('Test error')
      end
    end

    context 'when user is not super admin' do
      before { sign_in officer }

      it 'denies access' do
        patch demote_to_officer_internal_user_path(another_super_admin)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'GET /internal/user_management/:id/attendance_history' do
    let(:event1) { create(:event, date: 1.week.ago) }
    let(:event2) { create(:event, date: 2.weeks.ago) }
    let(:event3) { create(:event, date: 3.weeks.ago) }

    before do
      create(:attendance, user: regular_user, event: event1, status: 'present')
      create(:attendance, user: regular_user, event: event2, status: 'excused')
      create(:attendance, user: regular_user, event: event3, status: 'absent')
    end

    context 'when viewing own attendance history' do
      before { sign_in regular_user }

      it 'displays attendance history' do
        get attendance_history_internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
        expect(response.body).to include(event1.title)
        expect(response.body).to include(event2.title)
        expect(response.body).to include(event3.title)
      end

      it 'displays attendance statistics correctly' do
        get attendance_history_internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Present')
        expect(response.body).to include('Excused')
        expect(response.body).to include('Absent')
      end

      it 'displays most recent events first' do
        get attendance_history_internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
        event1_pos = response.body.index(event1.title)
        event3_pos = response.body.index(event3.title)
        expect(event1_pos).to be < event3_pos if event1_pos && event3_pos
      end
    end

    context 'when admin viewing another users attendance history' do
      before { sign_in super_admin }

      it 'allows access' do
        get attendance_history_internal_user_path(regular_user)
        expect(response).to have_http_status(:success)
      end
    end

    context 'when regular user viewing another users attendance history' do
      let(:other_user) { create(:user) }
      before { sign_in regular_user }

      it 'denies access' do
        get attendance_history_internal_user_path(other_user)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include('not authorized')
      end
    end
  end
end
