# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :user
  belongs_to :event

  # Constants for status values
  STATUSES = %w[present absent excused tardy].freeze

  # Validations
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :event_id, message: 'already has attendance recorded for this event' }

  # Scopes for filtering
  scope :present, -> { where(status: 'present') }
  scope :absent, -> { where(status: 'absent') }
  scope :excused, -> { where(status: 'excused') }
  scope :tardy, -> { where(status: 'tardy') }

  # Class method to record attendance for multiple users at once
  def self.record_for_event(event_id, attendances_hash)
    transaction do
      attendances_hash.each do |user_id, status|
        attendance = find_or_initialize_by(event_id: event_id, user_id: user_id)
        attendance.status = status
        attendance.save!
      end
    end
  end
end
