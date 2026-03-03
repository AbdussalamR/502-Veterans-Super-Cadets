# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'internal/events/show', type: :view do
  let(:user) { create(:user) }
  let(:event) do
    Event.create!(
      title: 'Title',
      date: Time.zone.today,
      end_time: Time.zone.today + 2.hours,
      location: 'Location',
      description: 'MyText'
    )
  end

  before(:each) do
    assign(:event, event)

    # Mock current_user helper
    allow(view).to receive(:current_user).and_return(user)
    allow(view).to receive(:user_signed_in?).and_return(true)

    # Mock the attendance_status_badge helper
    allow(view).to receive(:attendance_status_badge).and_return('<span class="badge bg-secondary">Not Recorded</span>'.html_safe)
  end

  it 'renders attributes in <p>' do
    render
    expect(rendered).to match(/Title/)
    expect(rendered).to match(/Location/)
    expect(rendered).to match(/MyText/)
  end

  context 'with approved excuses' do
    let(:admin_user) { create(:user, :officer) }
    let(:excused_user1) { create(:user, approval_status: 'approved') }
    let(:excused_user2) { create(:user, approval_status: 'approved') }

    before do
      Excuse.create!(member: excused_user1, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof1')
      Excuse.create!(member: excused_user2, event: event, reason: 'Doctor', status: 'approved', proof_link: 'https://example.com/proof2')
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it 'displays approved excuses section for admin users' do
      render
      expect(rendered).to match(/Approved Excuses/)
      expect(rendered).to match(/#{excused_user1.full_name}/)
      expect(rendered).to match(/#{excused_user2.full_name}/)
    end

    it 'displays the count of approved excuses' do
      render
      expect(rendered).to include('2')
      expect(rendered).to include('students have approved excuses')
    end

    it 'displays excused badge for each student' do
      render
      expect(rendered).to match(/Excused/)
    end
  end

  context 'without approved excuses' do
    let(:admin_user) { create(:user, :officer) }

    before do
      allow(view).to receive(:current_user).and_return(admin_user)
    end

    it 'does not display approved excuses section' do
      render
      expect(rendered).not_to match(/Approved Excuses/)
    end
  end

  context 'as regular user with approved excuses' do
    let(:excused_user) { create(:user, approval_status: 'approved') }

    before do
      Excuse.create!(member: excused_user, event: event, reason: 'Sick', status: 'approved', proof_link: 'https://example.com/proof')
    end

    it 'does not display approved excuses section' do
      render
      expect(rendered).not_to match(/Approved Excuses/)
    end
  end
end
