# frozen_string_literal: true

class AddApprovalStatusToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :approval_status, :string
    add_index :users, :approval_status
  end
end
