# frozen_string_literal: true

class PerformanceRequestMailer < ApplicationMailer
  def new_request_notification(performance_request, _director = nil)
    @request    = performance_request
    @from_name  = ENV.fetch('NOTIFICATION_FROM_NAME', 'Singing Cadets')
    @from_email = ENV.fetch('NOTIFICATION_FROM_EMAIL', 'no-reply@example.com')
    @recipient  = ENV.fetch('NOTIFICATION_REPLY_TO', @from_email)
    @app_host   = ENV.fetch('APP_HOST', 'localhost:3000')

    mail(
      to: @recipient,
      from: "#{@from_name} <#{@from_email}>",
      subject: "New Performance Request from #{@request.name} (#{@request.organization})"
    )
  end
end
