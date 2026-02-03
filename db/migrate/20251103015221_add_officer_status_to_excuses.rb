class AddOfficerStatusToExcuses < ActiveRecord::Migration[7.0]
  def change
    add_column :excuses, :officer_status, :string
    add_column :excuses, :officer_reviewed_at, :datetime
  end
end
