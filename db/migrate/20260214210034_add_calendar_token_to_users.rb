class AddCalendarTokenToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :calendar_token, :string
    add_index :users, :calendar_token
  end
end
