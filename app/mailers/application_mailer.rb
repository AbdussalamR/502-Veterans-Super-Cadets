# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  default from: -> { ApplicationMailer.default_from_address }
  layout 'mailer'

  def self.default_from_address
    email = Notifications::Config.from_email
    name = Notifications::Config.from_name

    email_address_with_name(email, name)
  end
end
