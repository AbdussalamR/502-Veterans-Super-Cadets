class AddSelfCheckinToEvents < ActiveRecord::Migration[7.0]
  def change
    add_column :events, :allow_self_checkin, :boolean, default: false, null: false
    add_column :events, :checkin_passcode, :string
  end
end
