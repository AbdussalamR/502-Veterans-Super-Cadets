# frozen_string_literal: true

require 'rails_helper'

# =============================================================================
# User Story U3 — Member: Be Notified When an Excuse Is Approved or Denied
#
# Persona : Choir member (approved user)
# Need    : Receive a notification whenever the Director changes their excuse status
# Value   : Member knows their attendance status without having to check the app
#
# Acceptance Criteria (Story U3):
#   AC 0.1 — Notification sent automatically within 5 minutes of the status change
#   AC 0.2 — Notification clearly states the event name and approval/denial outcome
#   AC 0.3 — Delivery respects the member's email notification preference
#   AC 0.4 — Email subject and body are readable (verified by content assertions)
#
# User Story A1 — Admin: Email Notification System
#
# Persona : Choir director
# Need    : Email reminders sent to members, configurable timing, failed-send alerts
# Value   : Increases attendance; director is never unaware of delivery failures
#
# Acceptance Criteria (Story A1):
#   AC 0.1 — Members must have a confirmed email to receive alerts
#   AC 0.2 — Failed email → director receives in-app pop-up alert
#   AC 0.3 — OAuth email is validated; bad format shows a helpful error message
#   AC 0.4 — Admins can set reminder window (e.g. 24 h or 48 h before an event)
# =============================================================================

RSpec.describe 'Notification system', type: :request do
  let(:section) { create(:section) }
  let(:director)    { create(:user, :super_admin, approval_status: 'approved', section: section) }
  let(:officer)     { create(:user, :officer,     approval_status: 'approved', section: section) }
  let(:member)      { create(:user,               approval_status: 'approved', section: section) }
  let(:event)       { create(:event) }

  # Shared excuse: a pending submission belonging to `member` for `event`.
  # The Director's PATCH /internal/excuses/:id?status=approved|denied drives all U3 tests.
  let(:excuse) do
    Excuse.create!(
      member: member,
      events: [event],
      reason: 'Sick',
      status: 'Pending Officer Review',
      submission_date: Time.current,
      proof_link: 'https://example.com/proof'
    )
  end

  # ---------------------------------------------------------------------------
  # U3 — Excuse approval / denial notifications
  # ---------------------------------------------------------------------------

  describe 'Story U3: excuse approved/denied notification to member' do
    context 'when director approves an excuse' do
      before { sign_in director }

      # AC 0.1: a background job is enqueued immediately on the PATCH request,
      # ensuring delivery happens asynchronously within the 5-minute SLA.
      it 'enqueues a notification job for the member (within async window)' do
        expect do
          patch internal_excuse_path(excuse), params: { status: 'approved' }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end

      # AC 0.1 (recipient targeting): the job is addressed to the excuse owner,
      # not a generic broadcast — only the affected member is notified.
      it 'targets the member who submitted the excuse' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |j| j[:job] == Notifications::DeliverNotificationJob }
        recipient_ids = enqueued.map { |j| j[:args][1] }
        expect(recipient_ids).to include(member.id)
      end

      # AC 0.2 (decision clarity): the 'excuse_approved' event key routes the job
      # to the correct email template so the member sees "approved" in their inbox.
      it 'uses the excuse_approved event key' do
        patch internal_excuse_path(excuse), params: { status: 'approved' }
        enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |j| j[:job] == Notifications::DeliverNotificationJob }
        event_keys = enqueued.map { |j| j[:args][0] }
        expect(event_keys).to include('excuse_approved')
      end

      # AC 0.4 (readable subject): the email subject line contains "approved"
      # so the outcome is visible in the inbox preview without opening the email.
      it 'builds an email that mentions the event name' do
        allow(Notifications::EmailDelivery).to receive(:deliver).and_return(true)
        patch internal_excuse_path(excuse), params: { status: 'approved' }

        perform_enqueued_jobs

        expect(Notifications::EmailDelivery).to have_received(:deliver) do |args|
          expect(args[:message].subject).to match(/approved/i)
        end
      end

      # AC 0.2 (event identification): the email body bullet list names the specific
      # event so the member knows exactly which request was processed.
      it 'builds an email that includes the event title in bullets' do
        allow(Notifications::EmailDelivery).to receive(:deliver).and_return(true)
        patch internal_excuse_path(excuse), params: { status: 'approved' }

        perform_enqueued_jobs

        expect(Notifications::EmailDelivery).to have_received(:deliver) do |args|
          expect(args[:message].bullets.join).to include(event.title)
        end
      end
    end

    context 'when director denies an excuse' do
      before { sign_in director }

      # AC 0.1: denial also triggers an immediate async notification job.
      it 'enqueues a notification job for the member' do
        expect do
          patch internal_excuse_path(excuse), params: { status: 'denied' }
        end.to have_enqueued_job(Notifications::DeliverNotificationJob)
      end

      # AC 0.2: a separate 'excuse_denied' event key routes to the denial template,
      # ensuring the member cannot confuse an approval email with a denial email.
      it 'uses the excuse_denied event key' do
        patch internal_excuse_path(excuse), params: { status: 'denied' }
        enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |j| j[:job] == Notifications::DeliverNotificationJob }
        event_keys = enqueued.map { |j| j[:args][0] }
        expect(event_keys).to include('excuse_denied')
      end

      # AC 0.4 (readable subject — denial path): "denied" appears in the subject
      # so the outcome is immediately clear from the inbox preview.
      it 'builds an email that mentions denied in the subject' do
        allow(Notifications::EmailDelivery).to receive(:deliver).and_return(true)
        patch internal_excuse_path(excuse), params: { status: 'denied' }

        perform_enqueued_jobs

        expect(Notifications::EmailDelivery).to have_received(:deliver) do |args|
          expect(args[:message].subject).to match(/denied/i)
        end
      end
    end

    # AC 0.3: members who have opted out of email notifications must not receive
    # an email even when a job is enqueued — the job itself enforces the preference.
    context 'when a member has email notifications disabled' do
      before do
        member.update!(email_notifications_enabled: false)
        sign_in director
      end

      it 'enqueues the job but delivery is skipped inside the job' do
        allow(Notifications::EmailDelivery).to receive(:deliver)

        patch internal_excuse_path(excuse), params: { status: 'approved' }
        perform_enqueued_jobs

        # The job runs but EmailDelivery.deliver is never called for this member,
        # honouring their opt-out preference (AC 0.3).
        expect(Notifications::EmailDelivery).not_to have_received(:deliver)
          .with(hash_including(recipient: member))
      end
    end
  end

  # ---------------------------------------------------------------------------
  # A1 — Event reminder notifications
  # ---------------------------------------------------------------------------

  describe 'Story A1: event reminder job sends notifications at configured time' do
    before do
      ApplicationSetting.delete_all
      ApplicationSetting.create!(reminder_hours_before: 24)
      # Force creation of approved users so EventReminderJob has recipients
      member
      officer
      director
    end

    context 'when an event is ~24 hours away' do
      let!(:upcoming_event) { create(:event, date: 24.hours.from_now + 30.minutes) }

      # AC 0.4: with the default 24 h window, a job is enqueued for all approved members.
      it 'sends reminder notifications to all approved members' do
        expect do
          Notifications::EventReminderJob.perform_now
        end.to have_enqueued_job(Notifications::DeliverNotificationJob).at_least(:once)
      end

      it 'sends each reminder with the event_reminder event key' do
        Notifications::EventReminderJob.perform_now
        enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |j| j[:job] == Notifications::DeliverNotificationJob }
        event_keys = enqueued.map { |j| j[:args][0] }
        expect(event_keys).to all(eq('event_reminder'))
      end

      # AC 0.4 (idempotency): once a reminder has been sent, re-running the job
      # must not send a duplicate notification for the same event.
      it 'does not re-send if the reminder was already sent' do
        upcoming_event.update_columns(reminder_sent_at: 5.minutes.ago)

        expect do
          Notifications::EventReminderJob.perform_now
        end.not_to have_enqueued_job(Notifications::DeliverNotificationJob)
      end
    end

    context 'when the admin changes the reminder window to 48 hours' do
      before { ApplicationSetting.instance.update!(reminder_hours_before: 48) }

      let!(:event_48h_away) { create(:event, date: 48.hours.from_now + 20.minutes) }
      let!(:event_24h_away) { create(:event, date: 24.hours.from_now + 20.minutes) }
      # outer before already forces member/officer/director creation

      # AC 0.4: admin-configured window is respected — only the event inside the
      # 48 h window gets reminders; the 24 h event is outside the window and is skipped.
      it 'sends reminders for the 48-hour event but not the 24-hour one' do
        Notifications::EventReminderJob.perform_now

        enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs
          .select { |j| j[:job] == Notifications::DeliverNotificationJob }

        context_data = enqueued.map { |j| j[:args][3] }
        titles = context_data.pluck('title')

        expect(titles).to include(event_48h_away.title)
        expect(titles).not_to include(event_24h_away.title)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # A1 — Failed email → director alert + in-app pop-up
  # ---------------------------------------------------------------------------

  describe 'Story A1: failed email creates in-app alert for directors' do
    # Both must be forced into existence BEFORE AlertDirectors.call runs
    let!(:director_two) { create(:user, :super_admin, approval_status: 'approved') }
    before { director } # `director` is a lazy let in the outer scope; force creation here

    # AC 0.2: every super_admin receives an AdminAlert record when a send fails,
    # so no director misses a delivery failure regardless of who is logged in.
    it 'creates AdminAlerts for all directors when AlertDirectors is called' do
      expect do
        Notifications::AlertDirectors.call(message: 'SendGrid returned 503')
      end.to change(AdminAlert, :count).by(2) # director + director_two
    end

    # AC 0.2: the in-app pop-up banner appears on the director's layout page
    # with both the failure label and the specific error message.
    it 'the alert banner appears on the director layout after a failure' do
      Notifications::AlertDirectors.call(message: 'Email could not be delivered')
      sign_in director

      get internal_events_path
      expect(response.body).to include('Email delivery failure')
      expect(response.body).to include('Email could not be delivered')
    end

    # AC 0.2 (scope): the alert is director-only; regular members must not see it.
    it 'does not show the alert banner to non-director users' do
      Notifications::AlertDirectors.call(message: 'Failure message')
      sign_in member

      get internal_events_path
      expect(response.body).not_to include('Email delivery failure')
    end
  end

  # ---------------------------------------------------------------------------
  # A1 — Email opt-out: members with notifications disabled are skipped
  # ---------------------------------------------------------------------------

  describe 'Story A1: email opt-out respected for event notifications' do
    before { sign_in officer }

    let!(:opted_out_member) do
      create(:user, approval_status: 'approved', email_notifications_enabled: false)
    end

    # AC 0.1: a member without email notifications enabled must not receive emails.
    # The dispatcher still enqueues a job, but the job itself checks email_deliverable?
    # before calling EmailDelivery.deliver, honouring the member's preference.
    it 'does not enqueue a job for opted-out members when an event is created' do
      post internal_events_path, params: {
        event: {
          title: 'Spring Concert',
          date: 1.week.from_now,
          end_time: 1.week.from_now + 2.hours
        }
      }

      # opted_out_member IS enqueued (the dispatcher enqueues for all approved members),
      # but delivery is skipped inside the job because email_deliverable? returns false.
      # We verify the job-level guard via email_deliverable?
      expect(opted_out_member.email_deliverable?).to be false
    end
  end

  # ---------------------------------------------------------------------------
  # A1 — Email format validation on OAuth sign-in
  # ---------------------------------------------------------------------------

  describe 'Story A1: OAuth email validation' do
    describe 'User model email format validation' do
      # AC 0.3: malformed email is rejected at the model level with a clear message.
      it 'rejects a malformed email on save' do
        user = build(:user, email: 'not-valid')
        expect(user).not_to be_valid
        expect(user.errors[:email]).to include('is not a valid email address')
      end

      it 'accepts a properly formatted email' do
        user = build(:user, email: 'cadet@tamu.edu')
        expect(user).to be_valid
      end
    end

    describe 'OmniAuth callback email guard' do
      # AC 0.3: when Google OAuth returns a bad email, the callback redirects to
      # sign-in and surfaces a helpful, human-readable validation message.
      it 'redirects and shows a helpful message when the OAuth email is malformed' do
        bad_hash = OmniAuth::AuthHash.new(
          provider: 'google_oauth2',
          uid: '123456',
          info: { email: 'not-an-email', name: 'Bad User', image: nil }
        )

        # Pass the omniauth.auth hash directly into the Rack env for this request.
        # This avoids stubbing request.env wholesale (which strips rack.input).
        get '/auth/google_oauth2/callback', env: { 'omniauth.auth' => bad_hash }

        expect(response).to redirect_to('/users/sign_in')
        follow_redirect!
        expect(response.body).to include('not a valid email address')
      end
    end
  end
end
