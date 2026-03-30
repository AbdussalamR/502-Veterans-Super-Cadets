class CreatePerformanceRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :performance_requests do |t|
      t.string  :name,          null: false
      t.string  :organization,  null: false
      t.date    :event_date,    null: false
      t.string  :location,      null: false
      t.string  :contact_email, null: false
      t.string  :status,        null: false, default: 'pending'
      t.text    :notes

      t.timestamps
    end

    add_index :performance_requests, :status
    add_index :performance_requests, :event_date
  end
end
