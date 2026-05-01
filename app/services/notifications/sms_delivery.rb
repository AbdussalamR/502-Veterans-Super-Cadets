# frozen_string_literal: true

require 'net/http'
require 'uri'

module Notifications
  class SmsDelivery
    TEXTBELT_URL = 'https://textbelt.com/text'

    def self.deliver(recipient:, sms_text:) # rubocop:disable Naming/PredicateMethod
      return false unless Notifications::Config.textbelt_configured?

      phone = recipient.phone_number.to_s.gsub(/\D/, '')
      return false if phone.blank?

      text = "Singing Cadets: #{sms_text}"
      text = "#{text[0, 157]}..." if text.length > 160

      params = { phone: phone, message: text, key: Notifications::Config.textbelt_api_key }
      response = Net::HTTP.post_form(URI(TEXTBELT_URL), params)

      result = JSON.parse(response.body)
      raise "TextBelt delivery failed: #{result['error']}" unless result['success']

      true
    end
  end
end
