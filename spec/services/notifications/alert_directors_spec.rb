# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::AlertDirectors do
  let!(:director_one) { create(:user, :super_admin, approval_status: 'approved') }
  let!(:director_two) { create(:user, :super_admin, approval_status: 'approved') }
  let!(:officer)   { create(:user, :officer,     approval_status: 'approved') }
  let!(:member)    { create(:user,               approval_status: 'approved') }

  describe '.call' do
    it 'creates an AdminAlert for every approved super_admin' do
      expect do
        described_class.call(message: 'Email failed for user@example.com')
      end.to change(AdminAlert, :count).by(2)
    end

    it 'does not create alerts for officers or members' do
      described_class.call(message: 'Email failed')
      alert_user_ids = AdminAlert.pluck(:user_id)
      expect(alert_user_ids).not_to include(officer.id, member.id)
    end

    it 'stores the provided message on each alert' do
      described_class.call(message: 'SendGrid returned 503')
      AdminAlert.find_each do |alert|
        expect(alert.message).to eq('SendGrid returned 503')
      end
    end

    it 'sets alert_type to email_failure' do
      described_class.call(message: 'Delivery failed')
      AdminAlert.find_each do |alert|
        expect(alert.alert_type).to eq('email_failure')
      end
    end

    it 'creates unread alerts (read_at is nil)' do
      described_class.call(message: 'Delivery failed')
      AdminAlert.find_each do |alert|
        expect(alert.read_at).to be_nil
      end
    end

    context 'when there are no approved super_admins' do
      before { User.super_admins.update_all(approval_status: 'pending') }

      it 'creates no alerts without raising an error' do
        expect do
          described_class.call(message: 'Delivery failed')
        end.not_to change(AdminAlert, :count)
      end
    end
  end
end
