# frozen_string_literal: true

module Notifications
  class EmailDelivery
    def self.deliver(recipient:, message:) # rubocop:disable Naming/PredicateMethod
      return false unless Notifications::Config.sendgrid_configured?
      return false if recipient.email.blank?

      mail = NotificationMailer.with(recipient: recipient, message: message).generic_notification.message
      sendgrid_mail = SendGrid::Mail.new
      sendgrid_mail.from = SendGrid::Email.new(
        email: Notifications::Config.from_email,
        name: Notifications::Config.from_name
      )
      sendgrid_mail.subject = mail.subject
      personalization = SendGrid::Personalization.new
      personalization.add_to(SendGrid::Email.new(email: recipient.email))
      sendgrid_mail.add_personalization(personalization)
      sendgrid_mail.add_content(SendGrid::Content.new(type: 'text/plain', value: mail.text_part&.decoded || mail.body.decoded))
      sendgrid_mail.add_content(SendGrid::Content.new(type: 'text/html', value: mail.html_part&.decoded.to_s)) if mail.html_part.present?
      sendgrid_mail.reply_to = SendGrid::Email.new(email: Notifications::Config.reply_to) if Notifications::Config.reply_to.present?

      response = sendgrid_client.client.mail._('send').post(request_body: sendgrid_mail.to_json)
      raise "SendGrid delivery failed with status #{response.status_code}" unless response.status_code.to_i.between?(200, 299)

      true
    end

    def self.sendgrid_client
      SendGrid::API.new(
        api_key: Notifications::Config.sendgrid_api_key,
        http_options: { cert_store: cert_store }
      )
    end

    def self.cert_store
      OpenSSL::X509::Store.new.tap(&:set_default_paths)
    end
  end
end
