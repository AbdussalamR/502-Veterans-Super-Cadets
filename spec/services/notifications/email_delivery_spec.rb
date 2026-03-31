# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Notifications::EmailDelivery do
  let(:recipient) { create(:user) }
  let(:message) do
    Notifications::MessageBuilder::Message.new(
      subject: 'Test subject',
      heading: 'Test heading',
      intro: 'Test intro',
      bullets: ['Bullet'],
      cta_label: 'Open',
      cta_url: 'http://localhost:3000/internal/events'
    )
  end

  it 'builds the SendGrid client with an explicit cert store' do
    store = instance_double(OpenSSL::X509::Store)
    sendgrid_api = instance_double(SendGrid::API)
    sendgrid_client = double('SendGrid client')
    send_endpoint = double('SendGrid send endpoint')
    response = instance_double(SendGrid::Response, status_code: '202')

    allow(Notifications::Config).to receive(:sendgrid_configured?).and_return(true)
    allow(Notifications::Config).to receive(:sendgrid_api_key).and_return('test-key')
    allow(OpenSSL::X509::Store).to receive(:new).and_return(store)
    allow(store).to receive(:set_default_paths)
    allow(SendGrid::API).to receive(:new).and_return(sendgrid_api)
    allow(sendgrid_api).to receive(:client).and_return(sendgrid_client)
    allow(sendgrid_client).to receive(:mail).and_return(sendgrid_client)
    allow(sendgrid_client).to receive(:_).with('send').and_return(send_endpoint)
    allow(send_endpoint).to receive(:post).and_return(response)

    described_class.deliver(recipient: recipient, message: message)

    expect(store).to have_received(:set_default_paths)
    expect(SendGrid::API).to have_received(:new).with(
      api_key: 'test-key',
      http_options: { cert_store: store }
    )
  end
end
