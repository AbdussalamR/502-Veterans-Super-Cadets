class AddPublishedToMedia < ActiveRecord::Migration[8.0]
  def change
    add_column :media_photos, :published, :boolean, null: false, default: false
    add_column :media_videos, :published, :boolean, null: false, default: false
  end
end
