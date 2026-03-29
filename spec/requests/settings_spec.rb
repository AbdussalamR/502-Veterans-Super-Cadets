# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Settings', type: :request do
  let(:director) { create(:user, :super_admin) }
  let(:officer)  { create(:user, :officer) }
  let(:member)   { create(:user) }

  before { ApplicationSetting.delete_all }

  describe 'GET /internal/settings/edit' do
    context 'as a director (super_admin)' do
      before { sign_in director }

      it 'returns 200 and renders the settings form' do
        get edit_internal_settings_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Notification Settings')
        expect(response.body).to include('reminder_hours_before')
      end

      it 'shows the current reminder_hours_before value' do
        ApplicationSetting.create!(reminder_hours_before: 12)
        get edit_internal_settings_path
        expect(response.body).to include('12')
      end
    end

    context 'as an officer' do
      before { sign_in officer }

      it 'redirects with a not-authorized alert' do
        get edit_internal_settings_path
        expect(response).to redirect_to(internal_events_path)
        follow_redirect!
        expect(response.body).to include('Not authorized')
      end
    end

    context 'as a regular member' do
      before { sign_in member }

      it 'redirects with a not-authorized alert' do
        get edit_internal_settings_path
        expect(response).to redirect_to(internal_events_path)
      end
    end

    context 'as an unauthenticated user' do
      it 'redirects to the sign-in page' do
        get edit_internal_settings_path
        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe 'PATCH /internal/settings' do
    context 'as a director' do
      before { sign_in director }

      context 'with valid params' do
        it 'updates reminder_hours_before and redirects back to the form' do
          patch internal_settings_path, params: { application_setting: { reminder_hours_before: 48 } }
          expect(ApplicationSetting.instance.reminder_hours_before).to eq(48)
          expect(response).to redirect_to(edit_internal_settings_path)
        end

        it 'shows a success flash message' do
          patch internal_settings_path, params: { application_setting: { reminder_hours_before: 6 } }
          follow_redirect!
          expect(response.body).to include('Notification settings saved')
        end
      end

      context 'with invalid params (zero hours)' do
        it 'does not persist the change' do
          ApplicationSetting.create!(reminder_hours_before: 24)
          patch internal_settings_path, params: { application_setting: { reminder_hours_before: 0 } }
          expect(ApplicationSetting.instance.reminder_hours_before).to eq(24)
        end

        it 'responds with 422 unprocessable entity' do
          patch internal_settings_path, params: { application_setting: { reminder_hours_before: 0 } }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end

      context 'with a non-integer value' do
        it 'responds with 422 and does not save' do
          ApplicationSetting.create!(reminder_hours_before: 24)
          patch internal_settings_path, params: { application_setting: { reminder_hours_before: 'abc' } }
          expect(ApplicationSetting.instance.reminder_hours_before).to eq(24)
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context 'as an officer' do
      before { sign_in officer }

      it 'redirects without updating' do
        ApplicationSetting.create!(reminder_hours_before: 24)
        patch internal_settings_path, params: { application_setting: { reminder_hours_before: 99 } }
        expect(response).to redirect_to(internal_events_path)
        expect(ApplicationSetting.instance.reminder_hours_before).to eq(24)
      end
    end
  end
end
