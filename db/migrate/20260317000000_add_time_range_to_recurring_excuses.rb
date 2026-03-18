# frozen_string_literal: true

class AddTimeRangeToRecurringExcuses < ActiveRecord::Migration[8.0]
  def change
    add_column :excuses, :recurring_start_time, :time
    add_column :excuses, :recurring_end_time, :time
  end
end
