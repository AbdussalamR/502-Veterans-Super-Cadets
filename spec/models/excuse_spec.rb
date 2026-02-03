# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Excuse, type: :model do
  describe 'associations' do
    it 'belongs to member (User)' do
      excuse = Excuse.reflect_on_association(:member)
      expect(excuse.macro).to eq(:belongs_to)
      expect(excuse.options[:class_name]).to eq('User')
    end

    it 'has many events through join table' do
      excuse = Excuse.reflect_on_association(:events)
      expect(excuse.macro).to eq(:has_many)
      expect(excuse.options[:through]).to eq(:events_to_excuses)
    end

    it 'has many reviewers through join table' do
      excuse = Excuse.reflect_on_association(:reviewers)
      expect(excuse.macro).to eq(:has_many)
      expect(excuse.options[:through]).to eq(:reviewers_to_excuses)
    end

    it 'provides event accessor methods' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'https://example.com/proof')
      expect(excuse.event).to eq(event)
      expect(excuse.event_id).to eq(event.id)
    end

    it 'provides reviewed_by accessor methods' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      reviewer = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'https://example.com/proof', reviewed_by: reviewer)
      expect(excuse.reviewed_by).to eq(reviewer)
      expect(excuse.reviewed_by_id).to eq(reviewer.id)
    end
  end

  describe 'validations' do
    it 'validates presence of reason' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, proof_link: 'https://example.com/proof')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:reason]).to include("can't be blank")
    end

    it 'validates presence of proof_link' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:proof_link]).to include("can't be blank")
    end

    it 'validates proof_link format' do
      event = create(:event)
      user = create(:user, approval_status: 'approved')
      excuse = Excuse.new(member: user, event: event, reason: 'Test', proof_link: 'not-a-url')
      expect(excuse).not_to be_valid
      expect(excuse.errors[:proof_link]).to include("must be a valid URL")
    end
  end

  describe 'scopes' do
    let(:event) { create(:event) }
    let(:user1) { create(:user, approval_status: 'approved') }
    let(:user2) { create(:user, approval_status: 'approved') }
    let(:user3) { create(:user, approval_status: 'approved') }

    before do
      @approved_excuse = Excuse.create!(member: user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      @pending_excuse = Excuse.create!(member: user2, event: event, reason: 'Doctor', status: 'pending', proof_link: 'https://example.com/proof2')
      @denied_excuse = Excuse.create!(member: user3, event: event, reason: 'Travel', status: 'denied', proof_link: 'https://example.com/proof3')
    end

    describe '.approved' do
      it 'returns only approved excuses' do
        expect(Excuse.approved).to include(@approved_excuse)
        expect(Excuse.approved).not_to include(@pending_excuse, @denied_excuse)
      end
    end

    describe '.pending' do
      it 'returns only pending excuses' do
        expect(Excuse.pending).to include(@pending_excuse)
        expect(Excuse.pending).not_to include(@approved_excuse, @denied_excuse)
      end
    end

    describe '.denied' do
      it 'returns only denied excuses' do
        expect(Excuse.denied).to include(@denied_excuse)
        expect(Excuse.denied).not_to include(@approved_excuse, @pending_excuse)
      end
    end
  end
end

