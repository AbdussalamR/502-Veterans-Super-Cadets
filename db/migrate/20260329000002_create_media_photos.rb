class CreateMediaPhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :media_photos do |t|
      t.string :page_name, null: false, default: 'media'
      t.string :caption
      t.integer :position, null: false, default: 0

      t.timestamps
    end

    add_index :media_photos, [:page_name, :position]
  end
end
