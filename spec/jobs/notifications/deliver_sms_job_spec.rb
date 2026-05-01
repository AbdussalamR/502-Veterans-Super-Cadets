# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::DeliverSmsJob, type: :job do
  let(:recipient) { create(:user, :with_sms) }
  let(:actor) { create(:user, :officer) }
  let(:context) { Notifications::Payloads.user(recipient) }

  it 'delivers SMS when the recipient has SMS enabled' do
    allow(Notifications::SmsDelivery).to receive(:deliver).and_return(true)

    described_class.perform_now('registration_approved', recipient.id, actor.id, context)

    expect(Notifications::SmsDelivery).to have_received(:deliver)
  end

  it 'skips delivery when SMS is disabled' do
    recipient.update!(sms_notifications_enabled: false)
    allow(Notifications::SmsDelivery).to receive(:deliver)

    described_class.perform_now('registration_approved', recipient.id, actor.id, context)

    expect(Notifications::SmsDelivery).not_to have_received(:deliver)
  end

  it 'skips delivery when recipient does not exist' do
    allow(Notifications::SmsDelivery).to receive(:deliver)

    described_class.perform_now('registration_approved', 0, actor.id, context)

    expect(Notifications::SmsDelivery).not_to have_received(:deliver)
  end

  it 'skips delivery for an unknown event key' do
    allow(Notifications::SmsDelivery).to receive(:deliver)

    described_class.perform_now('unknown_event_key', recipient.id, actor.id, context)

    expect(Notifications::SmsDelivery).not_to have_received(:deliver)
  end

  it 'enqueues a retry when SMS delivery raises an error' do
    allow(Notifications::SmsDelivery).to receive(:deliver)
      .and_raise(RuntimeError, 'TextBelt delivery failed: out of credits')

    expect do
      described_class.perform_now('registration_approved', recipient.id, actor.id, context)
    end.to have_enqueued_job(Notifications::DeliverSmsJob)
  end
end
