# frozen_string_literal: true

class AddPhonenumberToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :phonenumber, :text
  end
end
