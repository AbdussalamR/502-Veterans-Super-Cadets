# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::AdminAlerts', type: :request do
  let(:director) { create(:user, :super_admin) }
  let(:officer)  { create(:user, :officer) }

  describe 'PATCH /internal/admin_alerts/:id/dismiss' do
    context 'as a director who owns the alert' do
      before { sign_in director }

      let!(:alert) { AdminAlert.create!(user: director, message: 'Email delivery failed') }

      it 'marks the alert as read' do
        patch dismiss_internal_admin_alert_path(alert)
        expect(alert.reload.read_at).not_to be_nil
      end

      it 'redirects back after dismissal' do
        patch dismiss_internal_admin_alert_path(alert)
        expect(response).to have_http_status(:redirect)
      end

      it 'does not appear in the unread scope after dismissal' do
        patch dismiss_internal_admin_alert_path(alert)
        expect(director.admin_alerts.unread).not_to include(alert)
      end
    end

    context 'as an officer' do
      before { sign_in officer }

      let(:director_alert) { AdminAlert.create!(user: director, message: 'Alert') }

      it 'redirects with not-authorized alert' do
        patch dismiss_internal_admin_alert_path(director_alert)
        expect(response).to redirect_to(internal_events_path)
      end

      it 'does not mark the alert as read' do
        patch dismiss_internal_admin_alert_path(director_alert)
        expect(director_alert.reload.read_at).to be_nil
      end
    end
  end

  describe 'in-app alert banner visibility' do
    context 'when a director has unread alerts' do
      before do
        AdminAlert.create!(user: director, message: 'SendGrid returned 503')
        sign_in director
      end

      it 'shows the alert banner on internal pages' do
        get internal_events_path
        expect(response.body).to include('Email delivery failure')
        expect(response.body).to include('SendGrid returned 503')
      end

      it 'does not show the banner after the alert is dismissed' do
        alert = director.admin_alerts.unread.first
        patch dismiss_internal_admin_alert_path(alert)

        get internal_events_path
        expect(response.body).not_to include('SendGrid returned 503')
      end
    end

    context 'when a director has no unread alerts' do
      before { sign_in director }

      it 'does not render the alert banner' do
        get internal_events_path
        expect(response.body).not_to include('Email delivery failure')
      end
    end

    context 'as a regular member' do
      before do
        AdminAlert.create!(user: director, message: 'Some failure')
        sign_in create(:user)
      end

      it 'does not render alert banners at all' do
        get internal_events_path
        expect(response.body).not_to include('Email delivery failure')
      end
    end
  end
end
