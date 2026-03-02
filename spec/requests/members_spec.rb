# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Internal::Members', type: :request do
  let(:user) { create(:user) }

  describe 'GET /internal/my-demerits' do
    context 'as authenticated member (sunny day)' do
      before { sign_in user }

      it 'renders successfully' do
        get internal_my_demerits_path
        expect(response).to have_http_status(:success)
      end

      it 'displays the member demerits page' do
        get internal_my_demerits_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'with demerits present' do
      let(:officer) { create(:user, :officer) }

      before do
        sign_in user
        Demerit.create!(member: user, given_by: officer, value: 2, reason: 'Late to event', date: 1.day.ago)
        Demerit.create!(member: user, given_by: officer, value: 1, reason: 'Missed rehearsal', date: 2.days.ago)
      end

      it 'shows the member demerits' do
        get internal_my_demerits_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include('Late to event')
        expect(response.body).to include('Missed rehearsal')
      end
    end

    context 'with no demerits (edge case)' do
      before { sign_in user }

      it 'renders successfully even with no demerits' do
        get internal_my_demerits_path
        expect(response).to have_http_status(:success)
      end
    end

    context 'as unauthenticated user (rainy day)' do
      it 'redirects to sign in' do
        get internal_my_demerits_path
        expect(response).to redirect_to('/users/sign_in')
      end
    end
  end
end
