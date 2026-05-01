# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::SmsDelivery do
  let(:recipient) { create(:user, :with_sms) }
  let(:sms_text) { 'New event: Choir Practice on Monday, May 4 at 12:05 AM to 1:05 PM at Zoom.' }

  it 'posts to TextBelt and returns true on success' do
    allow(Notifications::Config).to receive(:textbelt_configured?).and_return(true)
    allow(Notifications::Config).to receive(:textbelt_api_key).and_return('test-key')

    stub_response = instance_double(Net::HTTPResponse, body: '{"success":true}')
    allow(Net::HTTP).to receive(:post_form).and_return(stub_response)

    result = described_class.deliver(recipient: recipient, sms_text: sms_text)

    expect(result).to be true
    expect(Net::HTTP).to have_received(:post_form).with(
      URI('https://textbelt.com/text'),
      hash_including(phone: '5551234567', key: 'test-key')
    )
  end

  it 'prefixes the message with Singing Cadets' do
    allow(Notifications::Config).to receive(:textbelt_configured?).and_return(true)
    allow(Notifications::Config).to receive(:textbelt_api_key).and_return('test-key')

    stub_response = instance_double(Net::HTTPResponse, body: '{"success":true}')
    allow(Net::HTTP).to receive(:post_form).and_return(stub_response)

    described_class.deliver(recipient: recipient, sms_text: sms_text)

    expect(Net::HTTP).to have_received(:post_form).with(
      anything,
      hash_including(message: start_with('Singing Cadets:'))
    )
  end

  it 'raises when TextBelt reports failure' do
    allow(Notifications::Config).to receive(:textbelt_configured?).and_return(true)
    allow(Notifications::Config).to receive(:textbelt_api_key).and_return('test-key')

    stub_response = instance_double(Net::HTTPResponse, body: '{"success":false,"error":"out of credits"}')
    allow(Net::HTTP).to receive(:post_form).and_return(stub_response)

    expect do
      described_class.deliver(recipient: recipient, sms_text: sms_text)
    end.to raise_error(RuntimeError, /out of credits/)
  end

  it 'returns false when TextBelt is not configured' do
    allow(Notifications::Config).to receive(:textbelt_configured?).and_return(false)

    result = described_class.deliver(recipient: recipient, sms_text: sms_text)

    expect(result).to be false
  end

  it 'returns false when recipient has no phone number' do
    recipient.update!(phone_number: nil)
    allow(Notifications::Config).to receive(:textbelt_configured?).and_return(true)

    result = described_class.deliver(recipient: recipient, sms_text: sms_text)

    expect(result).to be false
  end
end
