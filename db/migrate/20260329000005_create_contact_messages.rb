class CreateContactMessages < ActiveRecord::Migration[8.0]
  def change
    create_table :contact_messages do |t|
      t.string   :name,    null: false
      t.string   :email,   null: false
      t.text     :message, null: false
      t.datetime :read_at

      t.timestamps
    end

    add_index :contact_messages, :read_at
  end
end
