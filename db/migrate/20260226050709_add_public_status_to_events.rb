class AddPublicStatusToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :is_public, :boolean
    add_column :events, :ticket_url, :string
  end
end
