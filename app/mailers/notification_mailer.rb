# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def generic_notification
    @recipient = params[:recipient]
    @message = params[:message]

    mail(
      to: @recipient.email,
      subject: @message.subject,
      reply_to: Notifications::Config.reply_to
    )
  end
end
