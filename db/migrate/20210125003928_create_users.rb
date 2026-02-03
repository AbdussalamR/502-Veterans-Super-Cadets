# frozen_string_literal: true

class CreateUsers < ActiveRecord::Migration[6.0]
  def change
    create_table :users do |t|
      t.text :first_name
      t.text :last_name

      t.timestamps null: false
    end
  end
end
