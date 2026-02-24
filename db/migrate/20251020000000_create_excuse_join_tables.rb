class CreateExcuseJoinTables < ActiveRecord::Migration[7.0]
  def up
    create_table :events_to_excuse, if_not_exists: true do |t|
      t.bigint :event_id, null: false
      t.bigint :excuse_id, null: false
      t.timestamps
    end
    add_index :events_to_excuse, [:event_id] unless index_exists?(:events_to_excuse, :event_id)
    add_index :events_to_excuse, [:excuse_id] unless index_exists?(:events_to_excuse, :excuse_id)

    create_table :reviewers_to_excuse, if_not_exists: true do |t|
      t.bigint :reviewer_id, null: false
      t.bigint :excuse_id, null: false
      t.timestamps
    end
    add_index :reviewers_to_excuse, [:reviewer_id] unless index_exists?(:reviewers_to_excuse, :reviewer_id)
    add_index :reviewers_to_excuse, [:excuse_id] unless index_exists?(:reviewers_to_excuse, :excuse_id)

    # Only migrate existing data if the excuses table exists and has data
    if table_exists?(:excuses) && column_exists?(:excuses, :event_id)
      say_with_time "migrating existing excuse event/reviewer references" do
        # temporary anonymous AR class (use a local variable, not a constant)
        excuse_klass = Class.new(ActiveRecord::Base) do
          self.table_name = "excuses"
        end

        excuse_klass.reset_column_information
        excuse_klass.find_each do |e|
          if e.respond_to?(:event_id) && e.event_id.present?
            execute <<-SQL.squish
              INSERT INTO events_to_excuse (event_id, excuse_id, created_at, updated_at)
              VALUES (#{e.event_id.to_i}, #{e.id.to_i}, NOW(), NOW())
            SQL
          end

          if e.respond_to?(:reviewed_by_id) && e.reviewed_by_id.present?
            execute <<-SQL.squish
              INSERT INTO reviewers_to_excuse (reviewer_id, excuse_id, created_at, updated_at)
              VALUES (#{e.reviewed_by_id.to_i}, #{e.id.to_i}, NOW(), NOW())
            SQL
          end
        end
      end
    end

    if table_exists?(:excuses)
      remove_column :excuses, :event_id, :bigint if column_exists?(:excuses, :event_id)
      remove_column :excuses, :reviewed_by_id, :bigint if column_exists?(:excuses, :reviewed_by_id)
    end

    add_foreign_key :events_to_excuse, :events, column: :event_id unless foreign_key_exists?(:events_to_excuse, 
                                                                                             :events, column: :event_id)
    add_foreign_key :events_to_excuse, :excuses, column: :excuse_id if table_exists?(:excuses) && !foreign_key_exists?(
      :events_to_excuse, :excuses, column: :excuse_id
    )
    add_foreign_key :reviewers_to_excuse, :users, column: :reviewer_id unless foreign_key_exists?(:reviewers_to_excuse, 
                                                                                                  :users, column: :reviewer_id)
    if table_exists?(:excuses) && !foreign_key_exists?(
      :reviewers_to_excuse, :excuses, column: :excuse_id
    )
      add_foreign_key :reviewers_to_excuse, :excuses, 
                      column: :excuse_id
    end
  end

  def down
    add_column :excuses, :event_id, :bigint unless column_exists?(:excuses, :event_id)
    add_column :excuses, :reviewed_by_id, :bigint unless column_exists?(:excuses, :reviewed_by_id)

    execute <<-SQL.squish
      UPDATE excuses
      SET event_id = sub.event_id
      FROM (
        SELECT DISTINCT ON (excuse_id) excuse_id, event_id
        FROM events_to_excuse
        ORDER BY excuse_id, id
      ) AS sub
      WHERE excuses.id = sub.excuse_id
    SQL

    execute <<-SQL.squish
      UPDATE excuses
      SET reviewed_by_id = sub.reviewer_id
      FROM (
        SELECT DISTINCT ON (excuse_id) excuse_id, reviewer_id
        FROM reviewers_to_excuse
        ORDER BY excuse_id, id
      ) AS sub
      WHERE excuses.id = sub.excuse_id
    SQL

    drop_table :events_to_excuse if table_exists?(:events_to_excuse)
    drop_table :reviewers_to_excuse if table_exists?(:reviewers_to_excuse)
  end
end