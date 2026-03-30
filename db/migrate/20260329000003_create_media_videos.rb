class CreateMediaVideos < ActiveRecord::Migration[8.0]
  def change
    create_table :media_videos do |t|
      t.string :title
      t.string :youtube_url, null: false
      t.string :youtube_id, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
