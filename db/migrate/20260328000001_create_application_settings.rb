# frozen_string_literal: true

class CreateApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :application_settings do |t|
      t.integer :reminder_hours_before, null: false, default: 24
      t.timestamps
    end
  end
end
