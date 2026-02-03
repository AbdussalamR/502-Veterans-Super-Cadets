# frozen_string_literal: true

class SetDefaultApprovalStatusForUsers < ActiveRecord::Migration[7.0]
  def up
    # Set default for new users
    change_column_default :users, :approval_status, 'pending'

    # Update existing users based on role
    # Officers and super_admins are already approved
    execute <<-SQL.squish
      UPDATE users#{' '}
      SET approval_status = CASE
        WHEN role IN ('officer', 'super_admin') THEN 'approved'
        ELSE 'pending'
      END
    SQL
  end

  def down
    change_column_default :users, :approval_status, nil
  end
end
