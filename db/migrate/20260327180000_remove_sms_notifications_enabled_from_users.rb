# frozen_string_literal: true

class RemoveSmsNotificationsEnabledFromUsers < ActiveRecord::Migration[8.0]
  def change
    remove_column :users, :sms_notifications_enabled, :boolean if column_exists?(:users, :sms_notifications_enabled)
  end
end
