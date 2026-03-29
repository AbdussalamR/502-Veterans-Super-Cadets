# frozen_string_literal: true

class AddNotificationSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone_number, :string unless column_exists?(:users, :phone_number)
    add_column :users, :email_notifications_enabled, :boolean, default: true, null: false unless column_exists?(:users, :email_notifications_enabled)
    add_column :users, :sms_notifications_enabled, :boolean, default: true, null: false unless column_exists?(:users, :sms_notifications_enabled)
  end
end
