# frozen_string_literal: true

class CreateAttendances < ActiveRecord::Migration[7.0]
  def change
    create_table :attendances do |t|
      t.references :user, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.string :status, null: false, default: 'absent'
      t.text :note

      t.timestamps
    end

    add_index :attendances, %i[user_id event_id], unique: true
  end
end
