class AddSectionIdToUsers < ActiveRecord::Migration[7.0]
  def change
    add_reference :users, :section, null: true, foreign_key: true
  end
end
