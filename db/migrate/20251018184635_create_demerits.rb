class CreateDemerits < ActiveRecord::Migration[7.0]
  def change
    create_table :demerits do |t|
      t.references :member, null: false, foreign_key: { to_table: :users }
      t.references :given_by, null: false, foreign_key: { to_table: :users }
      t.decimal :value, precision: 3, scale: 2, default: 0.33
      t.datetime :date
      t.string :reason

      t.timestamps
    end
  end
end
