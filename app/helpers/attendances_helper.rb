# frozen_string_literal: true

module AttendancesHelper
  # Format absence points to follow the 0.33, 0.66, 1, 1.33, 1.66, 2... pattern
  def format_absence_points(points)
    # Get whole number and fractional part
    whole_part = points.to_i
    frac_part = points - whole_part
    
    # Round to nearest third (0, 0.33, 0.66)
    result = if frac_part < 0.17
               whole_part
             elsif frac_part < 0.5
               # Force exactly 0.33 instead of floating point approximation
               (whole_part + 0.33).round(2)
             elsif frac_part < 0.83
               # Force exactly 0.66 instead of floating point approximation
               (whole_part + 0.66).round(2)
             else
               whole_part + 1 # Round to next whole number if close
             end
    
    # Format to remove trailing zeros
    sprintf("%.2f", result).sub(/\.?0+$/, '')
  end
end