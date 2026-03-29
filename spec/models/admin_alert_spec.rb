# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AdminAlert, type: :model do
  let(:director) { create(:user, :super_admin) }

  describe 'associations' do
    it 'belongs to a user' do
      alert = AdminAlert.create!(user: director, message: 'Test alert')
      expect(alert.user).to eq(director)
    end
  end

  describe '.unread scope' do
    it 'returns alerts where read_at is nil' do
      unread = AdminAlert.create!(user: director, message: 'Unread alert')
      read   = AdminAlert.create!(user: director, message: 'Read alert', read_at: 1.hour.ago)

      expect(AdminAlert.unread).to include(unread)
      expect(AdminAlert.unread).not_to include(read)
    end
  end

  describe '#mark_read!' do
    it 'sets read_at to approximately the current time' do
      alert = AdminAlert.create!(user: director, message: 'Some failure')
      expect(alert.read_at).to be_nil

      alert.mark_read!
      expect(alert.read_at).to be_within(5.seconds).of(Time.current)
    end

    it 'persists the change to the database' do
      alert = AdminAlert.create!(user: director, message: 'Some failure')
      alert.mark_read!
      expect(alert.reload.read_at).not_to be_nil
    end
  end
end
