# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'internal/events/index', type: :view do
  let(:user) { create(:user) }
  let(:events) do
    [
      Event.create!(
        title: 'Title',
        date: Time.zone.today,
        end_time: Time.zone.today + 2.hours,
        location: 'Location',
        description: 'MyText'
      ),
      Event.create!(
        title: 'Title',
        date: Time.zone.today,
        end_time: Time.zone.today + 2.hours,
        location: 'Location',
        description: 'MyText'
      ),
    ]
  end

  before(:each) do
    assign(:events, events)
    assign(:upcoming_events, events)
    assign(:past_events, [])

    # Mock current_user helper
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:user_signed_in?).and_return(true)
  end

  it 'renders a list of events' do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Location/)
    expect(rendered).to match(/MyText/)
  end

  context 'with approved excuses for events' do
    let(:admin_user) { create(:user, :officer) }
    let(:event_with_excuses) do
      Event.create!(
        title: 'Event with Excuses',
        date: Time.zone.today,
        end_time: Time.zone.today + 2.hours,
        location: 'Test Location',
        description: 'Test description'
      )
    end
    let(:excused_user1) { create(:user, approval_status: 'approved') }
    let(:excused_user2) { create(:user, approval_status: 'approved') }

    before do
      Excuse.create!(member: excused_user1, event: event_with_excuses, reason: 'Sick', status: 'approved', 
                     proof_link: 'https://example.com/proof1')
      Excuse.create!(member: excused_user2, event: event_with_excuses, reason: 'Doctor', status: 'approved', 
                     proof_link: 'https://example.com/proof2')
      assign(:upcoming_events, [event_with_excuses])
      assign(:past_events, [])
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it 'displays excuse count for admin users' do
      render
      expect(rendered).to match(/2 excuses/)
    end

    it 'includes excuse icon' do
      render
      expect(rendered).to match(/bi-file-earmark-text/)
    end
  end

  context 'without approved excuses' do
    let(:admin_user) { create(:user, :officer) }

    before do
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it 'does not display excuse count' do
      render
      expect(rendered).not_to match(/excuses/)
    end
  end

  context 'as regular user with excuses on events' do
    let(:event_with_excuses) do
      Event.create!(
        title: 'Event with Excuses',
        date: Time.zone.today,
        end_time: Time.zone.today + 2.hours,
        location: 'Test Location',
        description: 'Test description'
      )
    end
    let(:excused_user) { create(:user, approval_status: 'approved') }

    before do
      Excuse.create!(member: excused_user, event: event_with_excuses, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof')
      assign(:upcoming_events, [event_with_excuses])
      assign(:past_events, [])
    end

    it 'does not display excuse count' do
      render
      expect(rendered).not_to match(/excuses/)
    end
  end
end
