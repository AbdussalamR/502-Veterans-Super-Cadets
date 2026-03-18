class CreateAuditionSessions < ActiveRecord::Migration[8.0]
  def change
    create_table :audition_sessions do |t|
      t.string :label, null: false
      t.datetime :start_datetime, null: false
      t.datetime :end_datetime, null: false
      t.string :location, null: false

      t.timestamps
    end
  end
end
