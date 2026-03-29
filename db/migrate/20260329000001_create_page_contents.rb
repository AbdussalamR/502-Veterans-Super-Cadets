class CreatePageContents < ActiveRecord::Migration[8.0]
  def change
    create_table :page_contents do |t|
      t.string :page_name, null: false
      t.string :content_key, null: false
      t.text :content_value
      t.boolean :is_draft, null: false, default: true

      t.timestamps
    end

    add_index :page_contents, [:page_name, :content_key, :is_draft], unique: true
  end
end
