# frozen_string_literal: true

class AddAreacodeToUser < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :area_code, :text
  end
end
