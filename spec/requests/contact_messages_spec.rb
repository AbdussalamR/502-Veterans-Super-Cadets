# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Contact form submission', type: :request do
  describe 'POST /public/contact' do
    let(:valid_params) do
      { name: 'Alice Aggie', email: 'alice@tamu.edu', message: 'Hello there!' }
    end

    context 'with valid params' do
      it 'creates a ContactMessage' do
        expect do
          post public_submit_contact_path, params: valid_params
        end.to change(ContactMessage, :count).by(1)
      end

      it 'stores the correct data' do
        post public_submit_contact_path, params: valid_params
        msg = ContactMessage.last
        expect(msg.name).to eq('Alice Aggie')
        expect(msg.email).to eq('alice@tamu.edu')
        expect(msg.message).to eq('Hello there!')
        expect(msg.read_at).to be_nil
      end

      it 'redirects to the contact page with a success notice' do
        post public_submit_contact_path, params: valid_params
        expect(response).to redirect_to(public_contact_path)
        expect(flash[:notice]).to include('Alice Aggie')
      end
    end

    context 'with invalid params' do
      it 'does not create a record when name is missing' do
        expect do
          post public_submit_contact_path, params: valid_params.merge(name: '')
        end.not_to change(ContactMessage, :count)
        expect(response).to redirect_to(public_contact_path)
        expect(flash[:alert]).to be_present
      end

      it 'does not create a record with a bad email' do
        expect do
          post public_submit_contact_path, params: valid_params.merge(email: 'not-an-email')
        end.not_to change(ContactMessage, :count)
      end

      it 'does not create a record when message is blank' do
        expect do
          post public_submit_contact_path, params: valid_params.merge(message: '')
        end.not_to change(ContactMessage, :count)
      end
    end
  end
end
