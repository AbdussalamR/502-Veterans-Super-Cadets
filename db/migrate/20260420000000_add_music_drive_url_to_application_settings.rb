# frozen_string_literal: true

class AddMusicDriveUrlToApplicationSettings < ActiveRecord::Migration[8.0]
  def change
    add_column :application_settings, :music_drive_url, :string
  end
end
