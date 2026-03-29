# frozen_string_literal: true

module Notifications
  class AlertDirectors
    def self.call(message:)
      Notifications::Audience.approved_super_admins.each do |director|
        AdminAlert.create!(
          user: director,
          message: message,
          alert_type: 'email_failure'
        )
      end
    end
  end
end
