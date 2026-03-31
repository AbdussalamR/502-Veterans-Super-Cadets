class ReAddIsPersonalToExcuses < ActiveRecord::Migration[8.0]
  def change
    return if column_exists?(:excuses, :is_personal)

    add_column :excuses, :is_personal, :boolean, default: false, null: false
  end
end
