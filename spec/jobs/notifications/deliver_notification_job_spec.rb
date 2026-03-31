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

  it 'skips delivery when recipient does not exist' do
    allow(Notifications::EmailDelivery).to receive(:deliver)

    described_class.perform_now('registration_approved', 0, actor.id, context)

    expect(Notifications::EmailDelivery).not_to have_received(:deliver)
  end

  it 'skips delivery when message cannot be built for the event_key' do
    allow(Notifications::EmailDelivery).to receive(:deliver)

    described_class.perform_now('unknown_event_key', recipient.id, actor.id, context)

    expect(Notifications::EmailDelivery).not_to have_received(:deliver)
  end

  describe 'when email delivery raises an error' do
    before do
      allow(Notifications::EmailDelivery).to receive(:deliver)
        .and_raise(RuntimeError, 'SendGrid delivery failed with status 503')
    end

    it 'enqueues a retry job instead of propagating the error immediately' do
      # retry_on rescues the error and schedules a retry through the queue;
      # it does NOT re-raise on the first failure.
      expect do
        described_class.perform_now('registration_approved', recipient.id, actor.id, context)
      end.to have_enqueued_job(Notifications::DeliverNotificationJob)
    end

    it 'AlertDirectors creates director alerts when called after permanent failure' do
      # The retry_on block calls AlertDirectors after all 3 attempts are exhausted.
      # We verify AlertDirectors works correctly here; the wiring is in the job class.
      director = create(:user, :super_admin)
      error = RuntimeError.new('SendGrid delivery failed with status 503')

      expect do
        Notifications::AlertDirectors.call(
          message: "An email could not be delivered after 3 attempts. Error: #{error.message}"
        )
      end.to change(AdminAlert, :count).by(1)

      expect(AdminAlert.last.user).to eq(director)
      expect(AdminAlert.last.message).to include('SendGrid delivery failed')
    end
  end
end
