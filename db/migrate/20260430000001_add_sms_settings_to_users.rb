# frozen_string_literal: true

class AddSmsSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :carrier, :string unless column_exists?(:users, :carrier)
    add_column :users, :sms_notifications_enabled, :boolean, default: false, null: false unless column_exists?(:users, :sms_notifications_enabled)
  end
end
