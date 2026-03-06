# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'is invalid without an email' do
      user = build(:user, email: nil)
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("can't be blank")
    end

    it 'is invalid without a full_name' do
      user = build(:user, full_name: nil)
      expect(user).not_to be_valid
      expect(user.errors[:full_name]).to include("can't be blank")
    end

    it 'is invalid without a uid' do
      user = build(:user, uid: nil)
      expect(user).not_to be_valid
      expect(user.errors[:uid]).to include("can't be blank")
    end

    it 'is invalid with invalid role' do
      user = build(:user, role: 'invalid_role')
      expect(user).not_to be_valid
      expect(user.errors[:role]).to include('is not included in the list')
    end

    it 'is invalid with invalid approval_status' do
      user = build(:user, approval_status: 'invalid_status')
      expect(user).not_to be_valid
      expect(user.errors[:approval_status]).to include('is not included in the list')
    end
  end

  describe 'role methods' do
    let(:user) { create(:user) }
    let(:officer) { create(:user, :officer) }
    let(:super_admin) { create(:user, :super_admin) }

    it 'returns correct role status' do
      expect(user.user?).to be true
      expect(user.officer?).to be false
      expect(user.super_admin?).to be false
      expect(user.admin?).to be false

      expect(officer.user?).to be false
      expect(officer.officer?).to be true
      expect(officer.super_admin?).to be false
      expect(officer.admin?).to be true

      expect(super_admin.user?).to be false
      expect(super_admin.officer?).to be false
      expect(super_admin.super_admin?).to be true
      expect(super_admin.admin?).to be true
    end
  end

  describe 'approval status methods' do
    let(:pending_user) { create(:user, :pending) }
    let(:approved_user) { create(:user) }
    let(:rejected_user) { create(:user, :rejected) }

    it 'returns correct approval status' do
      expect(pending_user.pending?).to be true
      expect(pending_user.approved?).to be false
      expect(pending_user.rejected?).to be false

      expect(approved_user.pending?).to be false
      expect(approved_user.approved?).to be true
      expect(approved_user.rejected?).to be false

      expect(rejected_user.pending?).to be false
      expect(rejected_user.approved?).to be false
      expect(rejected_user.rejected?).to be true
    end
  end

  describe 'associations' do
    it 'has many attendances' do
      user = create(:user)
      expect(user.attendances).to be_empty
    end

    it 'has many attended_events through attendances' do
      user = create(:user)
      expect(user.attended_events).to be_empty
    end

    it 'has many excuses' do
      user = create(:user)
      expect(user.excuses).to be_empty
    end
  end

  describe '.from_google' do
    let(:google_params) do
      {
        email: 'test@tamu.edu',
        full_name: 'Test User',
        uid: '12345',
        avatar_url: 'http://example.com/avatar.png'
      }
    end

    context 'when user does not exist' do
      it 'creates a new user with regular role' do
        expect {
          User.from_google(**google_params)
        }.to change(User, :count).by(1)

        user = User.last
        expect(user.email).to eq('test@tamu.edu')
        expect(user.full_name).to eq('Test User')
        expect(user.uid).to eq('12345')
        expect(user.avatar_url).to eq('http://example.com/avatar.png')
        expect(user.role).to eq('user')
        expect(user.approval_status).to eq('pending')
      end

      it 'creates a super admin when email is in super admin list' do
        allow(ENV).to receive(:[]).with('SUPER_ADMIN_EMAILS').and_return('test@tamu.edu')
        user = User.from_google(**google_params)
        expect(user.role).to eq('super_admin')
        expect(user.approval_status).to eq('approved')
      end
    end

    context 'when user already exists' do
      let!(:existing_user) { create(:user, email: 'test@tamu.edu', role: 'officer') }

      it 'updates existing user without changing role' do
        expect {
          User.from_google(**google_params)
        }.not_to change(User, :count)

        existing_user.reload
        expect(existing_user.full_name).to eq('Test User')
        expect(existing_user.uid).to eq('12345')
        expect(existing_user.role).to eq('officer') # unchanged
      end
    end
  end

  describe 'permission methods' do
    let(:user) { create(:user) }
    let(:officer) { create(:user, :officer) }
    let(:super_admin) { create(:user, :super_admin) }

    describe '#can_promote_users?' do
      it 'returns false for regular users' do
        expect(user.can_promote_users?).to be false
      end

      it 'returns false for officers' do
        expect(officer.can_promote_users?).to be false
      end

      it 'returns true for super admins' do
        expect(super_admin.can_promote_users?).to be true
      end
    end

    describe '#can_perform_admin_actions?' do
      it 'returns false for regular users' do
        expect(user.can_perform_admin_actions?).to be false
      end

      it 'returns true for officers' do
        expect(officer.can_perform_admin_actions?).to be true
      end

      it 'returns true for super admins' do
        expect(super_admin.can_perform_admin_actions?).to be true
      end
    end
  end

  describe 'promotion and demotion methods' do
    let(:user) { create(:user) }
    let(:officer) { create(:user, :officer) }
    let(:super_admin) { create(:user, :super_admin) }
    let(:another_super_admin) { create(:user, :super_admin) }

    describe '#promote_to_officer!' do
      it 'promotes user to officer' do
        user.promote_to_officer!(promoted_by: super_admin)
        expect(user.role).to eq('officer')
      end

      it 'raises error if promoter is not super admin' do
        expect {
          user.promote_to_officer!(promoted_by: officer)
        }.to raise_error('Only super admins can promote users')
      end

      it 'raises error if user is already an officer' do
        expect {
          officer.promote_to_officer!(promoted_by: super_admin)
        }.to raise_error('User is already an officer or higher')
      end
    end

    describe '#promote_to_super_admin!' do
      it 'promotes user to super admin' do
        user.promote_to_super_admin!(promoted_by: super_admin)
        expect(user.role).to eq('super_admin')
      end

      it 'promotes officer to super admin' do
        officer.promote_to_super_admin!(promoted_by: super_admin)
        expect(officer.role).to eq('super_admin')
      end

      it 'raises error if promoter is not super admin' do
        expect {
          user.promote_to_super_admin!(promoted_by: officer)
        }.to raise_error('Only super admins can promote users')
      end

      it 'raises error if user is already a super admin' do
        expect {
          super_admin.promote_to_super_admin!(promoted_by: another_super_admin)
        }.to raise_error('User is already a super admin')
      end
    end

    describe '#demote_to_user!' do
      it 'demotes officer to user' do
        officer.demote_to_user!(demoted_by: super_admin)
        expect(officer.role).to eq('user')
      end

      it 'demotes super admin to user' do
        another_super_admin.demote_to_user!(demoted_by: super_admin)
        expect(another_super_admin.role).to eq('user')
      end

      it 'raises error if demoter is not super admin' do
        expect {
          officer.demote_to_user!(demoted_by: officer)
        }.to raise_error('Only super admins can demote users')
      end

      it 'raises error if trying to demote self' do
        expect {
          super_admin.demote_to_user!(demoted_by: super_admin)
        }.to raise_error('Cannot demote yourself')
      end

      it 'raises error if user is already a regular user' do
        expect {
          user.demote_to_user!(demoted_by: super_admin)
        }.to raise_error('User is already a regular user')
      end
    end

    describe '#demote_to_officer!' do
      it 'demotes super admin to officer' do
        another_super_admin.demote_to_officer!(demoted_by: super_admin)
        expect(another_super_admin.role).to eq('officer')
      end

      it 'raises error if demoter is not super admin' do
        expect {
          another_super_admin.demote_to_officer!(demoted_by: officer)
        }.to raise_error('Only super admins can demote users')
      end

      it 'raises error if trying to demote self' do
        expect {
          super_admin.demote_to_officer!(demoted_by: super_admin)
        }.to raise_error('Cannot demote yourself')
      end

      it 'raises error if user is not a super admin' do
        expect {
          officer.demote_to_officer!(demoted_by: super_admin)
        }.to raise_error('User is not a super admin')
      end
    end
  end

  describe 'approval methods' do
    let(:pending_user) { create(:user, :pending) }
    let(:officer) { create(:user, :officer) }
    let(:super_admin) { create(:user, :super_admin) }

    describe '#approve!' do
      it 'approves a pending user by officer' do
        pending_user.approve!(approved_by: officer)
        expect(pending_user.approval_status).to eq('approved')
      end

      it 'approves a pending user by super admin' do
        pending_user.approve!(approved_by: super_admin)
        expect(pending_user.approval_status).to eq('approved')
      end

      it 'raises error if approver is not admin' do
        regular_user = create(:user)
        expect {
          pending_user.approve!(approved_by: regular_user)
        }.to raise_error('Only officers or super admins can approve users')
      end

      it 'raises error if user is already approved' do
        approved_user = create(:user, approval_status: 'approved')
        expect {
          approved_user.approve!(approved_by: officer)
        }.to raise_error('User is already approved')
      end
    end

    describe '#reject!' do
      it 'rejects a pending user by officer' do
        pending_user.reject!(rejected_by: officer)
        expect(pending_user.approval_status).to eq('rejected')
      end

      it 'rejects a pending user by super admin' do
        pending_user.reject!(rejected_by: super_admin)
        expect(pending_user.approval_status).to eq('rejected')
      end

      it 'raises error if rejector is not admin' do
        regular_user = create(:user)
        expect {
          pending_user.reject!(rejected_by: regular_user)
        }.to raise_error('Only officers or super admins can reject users')
      end

      it 'raises error if user is already rejected' do
        rejected_user = create(:user, :rejected)
        expect {
          rejected_user.reject!(rejected_by: officer)
        }.to raise_error('User is already rejected')
      end
    end
  end

  describe 'scopes' do
    let!(:officer) { create(:user, :officer) }
    let!(:super_admin) { create(:user, :super_admin) }
    let!(:regular_user) { create(:user) }
    let!(:pending_user) { create(:user, :pending) }
    let!(:rejected_user) { create(:user, :rejected) }

    describe '.officers' do
      it 'returns only officers' do
        expect(User.officers).to include(officer)
        expect(User.officers).not_to include(super_admin, regular_user)
      end
    end

    describe '.super_admins' do
      it 'returns only super admins' do
        expect(User.super_admins).to include(super_admin)
        expect(User.super_admins).not_to include(officer, regular_user)
      end
    end

    describe '.admins' do
      it 'returns officers and super admins' do
        expect(User.admins).to include(officer, super_admin)
        expect(User.admins).not_to include(regular_user)
      end
    end

    describe '.pending' do
      it 'returns only pending users' do
        expect(User.pending).to include(pending_user)
        expect(User.pending).not_to include(regular_user, rejected_user)
      end
    end

    describe '.approved' do
      it 'returns only approved users' do
        expect(User.approved).to include(regular_user, officer, super_admin)
        expect(User.approved).not_to include(pending_user, rejected_user)
      end
    end

    describe '.rejected' do
      it 'returns only rejected users' do
        expect(User.rejected).to include(rejected_user)
        expect(User.rejected).not_to include(regular_user, pending_user)
      end
    end
  end
end
