class ConfirmDemeritsValueAsInteger < ActiveRecord::Migration[7.0]
  def change
    # Ensure the value column is integer type
    change_column :demerits, :value, :integer, default: 1
  end
end
