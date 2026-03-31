# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::EventReminderJob, type: :job do
  let!(:member_one) { create(:user, approval_status: 'approved') }
  let!(:member_two) { create(:user, approval_status: 'approved') }
  let!(:pending_user) { create(:user, :pending) }

  before do
    # Ensure a clean single settings row
    ApplicationSetting.delete_all
    ApplicationSetting.create!(reminder_hours_before: 24)
  end

  describe '#perform' do
    context 'when an event falls in the reminder window' do
      let!(:event) { create(:event, date: 24.hours.from_now + 30.minutes) }

      it 'enqueues DeliverNotificationJob for each approved member' do
        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
          .exactly(2).times
      end

      it 'stamps reminder_sent_at on the event' do
        described_class.perform_now
        expect(event.reload.reminder_sent_at).not_to be_nil
      end

      it 'does not send a second reminder if already stamped' do
        event.update_columns(reminder_sent_at: 1.minute.ago)

        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DeliverNotificationJob)
      end

      it 'does not enqueue for pending (unapproved) members' do
        # Only member_one and member_two are approved; pending_user should be excluded
        described_class.perform_now
        enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs
        recipient_ids = enqueued.map { |j| j[:args][1] }
        expect(recipient_ids).not_to include(pending_user.id)
      end
    end

    context 'when an event is outside the reminder window' do
      let!(:far_future_event) { create(:event, date: 48.hours.from_now) }
      let!(:past_event) { create(:event, date: 1.week.ago, end_time: 1.week.ago + 1.hour) }

      it 'does not enqueue jobs for events too far in the future' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DeliverNotificationJob)
      end

      it 'does not enqueue jobs for past events' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'when admin sets a custom reminder window' do
      before do
        ApplicationSetting.instance.update!(reminder_hours_before: 48)
      end

      let!(:event_at_48h) { create(:event, date: 48.hours.from_now + 30.minutes) }

      it 'uses the configured hours instead of the default 24' do
        # member_one and member_two are both approved, so at least 2 jobs will be enqueued
        expect do
          described_class.perform_now
        end.to have_enqueued_job(Notifications::DeliverNotificationJob).at_least(:once)
      end
    end

    context 'when there are no upcoming events' do
      it 'enqueues nothing' do
        expect do
          described_class.perform_now
        end.not_to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end
  end
end
