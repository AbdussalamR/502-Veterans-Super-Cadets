class AddRecurringFieldsToExcuses < ActiveRecord::Migration[7.0]
  def change
    add_column :excuses, :recurring, :boolean, default: false, null: false
    add_column :excuses, :recurring_days, :string
  end
end
