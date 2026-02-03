class ChangeDemeritsValueToDecimalType < ActiveRecord::Migration[7.0]
  def change
    change_column :demerits, :value, :decimal, precision: 3, scale: 2, default: 0.33
  end
end
