# frozen_string_literal: true

class AdminAlert < ApplicationRecord
  belongs_to :user

  scope :unread, -> { where(read_at: nil) }

  def mark_read!
    update!(read_at: Time.current)
  end
end
