# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'attendances/new', type: :view do
  let(:admin_user) { create(:user, :officer) }
  let(:event) do
    Event.create!(
      title: 'Test Event',
      date: Time.zone.today,
      end_time: Time.zone.today + 2.hours,
      location: 'Test Location',
      description: 'Test description'
    )
  end
  let(:user1) { create(:user, approval_status: 'approved') }
  let(:user2) { create(:user, approval_status: 'approved') }

  before do
    assign(:event, event)
    assign(:users, [user1, user2])
    assign(:attendances, {
      user1.id => event.attendances.build(user: user1, status: 'absent'),
      user2.id => event.attendances.build(user: user2, status: 'absent')
    })
    assign(:excused_user_ids, [])
    allow(view).to receive(:current_user).and_return(admin_user)
  end

  it 'renders attendance form' do
    render
    expect(rendered).to match(/Take Attendance for/)
    expect(rendered).to match(/#{user1.full_name}/)
    expect(rendered).to match(/#{user2.full_name}/)
  end

  context 'with approved excuses' do
    let(:excused_user) { create(:user, approval_status: 'approved') }

    before do
      Excuse.create!(member: excused_user, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof')
      assign(:users, [user1, user2, excused_user])
      assign(:attendances, {
        user1.id => event.attendances.build(user: user1, status: 'absent'),
        user2.id => event.attendances.build(user: user2, status: 'absent'),
        excused_user.id => event.attendances.build(user: excused_user, status: 'excused')
      })
      assign(:excused_user_ids, [excused_user.id])
    end

    it 'displays alert for excused users' do
      render
      expect(rendered).to match(/approved excuses and will be marked as excused/)
    end

    it 'displays excused user with badge' do
      render
      expect(rendered).to match(/#{excused_user.full_name}/)
      expect(rendered).to match(/Approved Excuse/)
    end

    it 'marks excused users with different background' do
      render
      # Check for the greyed out styling
      expect(rendered).to match(/background-color: #f8f9fa/)
    end

    it 'disables radio buttons for excused users' do
      render
      # The disabled attribute should be present for excused users
      expect(rendered).to match(/disabled/)
    end
  end

  context 'without approved excuses' do
    it 'does not display alert' do
      render
      expect(rendered).not_to match(/approved excuses/)
    end

    it 'does not display excuse badges' do
      render
      expect(rendered).not_to match(/Approved Excuse/)
    end
  end
end

