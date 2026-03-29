# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::DeliverNotificationJob, type: :job do
  let(:recipient) { create(:user) }
  let(:actor) { create(:user, :officer) }
  let(:context) { Notifications::Payloads.user(recipient) }

  it 'delivers email when the recipient accepts email notifications' do
    allow(Notifications::EmailDelivery).to receive(:deliver).and_return(true)

    described_class.perform_now('registration_approved', recipient.id, actor.id, context)

    expect(Notifications::EmailDelivery).to have_received(:deliver)
  end

  it 'skips disabled email delivery' do
    recipient.update!(email_notifications_enabled: false)
    allow(Notifications::EmailDelivery).to receive(:deliver).and_return(true)

    described_class.perform_now('registration_approved', recipient.id, actor.id, context)

    expect(Notifications::EmailDelivery).not_to have_received(:deliver)
  end
end
