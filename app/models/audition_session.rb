class AuditionSession < ApplicationRecord
  validates :label, :start_datetime, :end_datetime, :location, presence: true
  validate :end_after_start

  default_scope { order(start_datetime: :asc) }

  private

  def end_after_start
    return unless start_datetime && end_datetime
    
    errors.add(:end_datetime, "must be after start") if end_datetime <= start_datetime
  end
end
