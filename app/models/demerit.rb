class Demerit < ApplicationRecord
  belongs_to :member, class_name: 'User', foreign_key: 'member_id'
  belongs_to :given_by, class_name: 'User', foreign_key: 'given_by_id'
  
  validates :value, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :reason, presence: true
  validates :date, presence: true
  
  before_validation :set_default_date
  
  # Calculate absence points (1 discipline point value = 0.33 absence points, rounds to 1.0 after 3)
  def absence_points
    # Calculate absence points: discipline point value * 0.33
    points = value.to_f * 0.33
    
    # Round discipline points: if result is 0.99 (value of 3), round to 1.0
    # Check if within 0.01 of a whole number (inclusive)
    rounded_points = points.round(2)
    whole_part = rounded_points.round
    if (rounded_points - whole_part).abs <= 0.01
      whole_part.to_f
    else
      rounded_points
    end
  end
  
  private
  
  def set_default_date
    self.date ||= Time.current
  end
end
