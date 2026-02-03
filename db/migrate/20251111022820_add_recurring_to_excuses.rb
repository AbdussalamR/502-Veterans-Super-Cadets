class AddRecurringToExcuses < ActiveRecord::Migration[7.0]
  def change
    add_column :excuses, :start_date, :datetime
    add_column :excuses, :end_date, :datetime
    add_column :excuses, :frequency, :string
  end
end
