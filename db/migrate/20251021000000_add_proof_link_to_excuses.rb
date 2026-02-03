class AddProofLinkToExcuses < ActiveRecord::Migration[7.0]
  def up
    add_column :excuses, :proof_link, :string unless column_exists?(:excuses, :proof_link)
  end

  def down
    remove_column :excuses, :proof_link if column_exists?(:excuses, :proof_link)
  end
end