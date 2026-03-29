# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactMessage, type: :model do
  describe 'validations' do
    it 'is valid with name, valid email, and message' do
      msg = build(:contact_message)
      expect(msg).to be_valid
    end

    it 'is invalid without a name' do
      expect(build(:contact_message, name: nil)).not_to be_valid
    end

    it 'is invalid without an email' do
      expect(build(:contact_message, email: nil)).not_to be_valid
    end

    it 'is invalid with a malformed email' do
      expect(build(:contact_message, email: 'not-an-email')).not_to be_valid
    end

    it 'is invalid without a message' do
      expect(build(:contact_message, message: nil)).not_to be_valid
    end
  end

  describe '#unread?' do
    it 'returns true when read_at is nil' do
      msg = build(:contact_message, read_at: nil)
      expect(msg.unread?).to be true
    end

    it 'returns false when read_at is set' do
      msg = build(:contact_message, :read)
      expect(msg.unread?).to be false
    end
  end

  describe '#read!' do
    it 'sets read_at to the current time' do
      msg = create(:contact_message)
      expect { msg.read! }.to change { msg.reload.read_at }.from(nil)
    end
  end

  describe 'scopes' do
    let!(:unread_msg) { create(:contact_message) }
    let!(:read_msg)   { create(:contact_message, :read) }

    it '.unread returns only unread messages' do
      expect(ContactMessage.unread).to include(unread_msg)
      expect(ContactMessage.unread).not_to include(read_msg)
    end

    it '.recent returns messages in reverse chronological order' do
      older = create(:contact_message, created_at: 2.days.ago)
      newer = create(:contact_message, created_at: 1.day.ago)
      ids = ContactMessage.recent.map(&:id)
      expect(ids.index(newer.id)).to be < ids.index(older.id)
    end
  end
end
