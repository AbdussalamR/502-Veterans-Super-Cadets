# frozen_string_literal: true

class ConsolidateAdminsIntoUsers < ActiveRecord::Migration[7.0]
  def change
    # Drop the old users table since it wasn't configured with OAuth
    drop_table :users if table_exists?(:users)

    # Rename admins table to users and add role column
    rename_table :admins, :users

    # Add role column with default 'user' role
    add_column :users, :role, :string, default: 'user', null: false

    # Add index on role for faster queries
    add_index :users, :role

    # Add provider column default value (it was already there but let's make sure it's set)
    change_column_default :users, :provider, 'google_oauth2'
  end
end
