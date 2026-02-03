class CreateExcuses < ActiveRecord::Migration[6.1]
  def change
    create_table :excuses do |t|
      t.references :member, null: false, foreign_key: { to_table: :users }
      t.references :event, null: false, foreign_key: true
      t.text :reason
      t.datetime :submission_date
      t.string :status
      t.references :reviewed_by, foreign_key: { to_table: :users }
      t.datetime :reviewed_date

      t.timestamps
    end
  end
end