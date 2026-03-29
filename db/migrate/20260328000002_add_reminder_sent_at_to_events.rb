# frozen_string_literal: true

class AddReminderSentAtToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :reminder_sent_at, :datetime
  end
end
