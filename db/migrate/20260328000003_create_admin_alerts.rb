# frozen_string_literal: true

class CreateAdminAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :admin_alerts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :message, null: false
      t.string :alert_type, null: false, default: 'email_failure'
      t.datetime :read_at
      t.timestamps
    end

    add_index :admin_alerts, [:user_id, :read_at]
  end
end
