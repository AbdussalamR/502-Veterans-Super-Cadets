# frozen_string_literal: true

module EventsHelper
  def attendance_status_badge(user, event)
    return '' unless user

    attendance = user.attendances.find_by(event: event)

    if attendance
      case attendance.status
      when 'present'
        content_tag :span, 'Present', class: 'badge bg-success'
      when 'absent'
        content_tag :span, 'Absent', class: 'badge bg-danger'
      when 'excused'
        content_tag :span, 'Excused', class: 'badge bg-warning text-dark'
      when 'tardy'
        content_tag :span, 'Present (Tardy)', class: 'badge bg-info text-white'
      end
    else
      content_tag :span, 'Not Recorded', class: 'badge bg-secondary'
    end
  end
end
