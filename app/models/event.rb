# frozen_string_literal: true

class Event < ApplicationRecord
  alias_attribute :start_time, :date
  has_many :attendances, dependent: :destroy
  has_many :attending_users, through: :attendances, source: :user

  # New join associations for excuses (many-to-many)
  has_many :events_to_excuses,
           class_name: 'EventsToExcuse',
           dependent: :destroy
  has_many :excuses, through: :events_to_excuses, dependent: :destroy

  # Validations
  validates :title, presence: true
  validates :date, presence: true
  validates :end_time, presence: true
  validate :end_time_after_start_time
  validates :checkin_passcode, format: { with: /\A\d{4}\z/, message: 'must be a 4-digit number' },
                               if: :allow_self_checkin?

  # Virtual attributes for repeating events (not saved to the database)
  attr_accessor :repeat_weekly
  
  attr_reader :repeat_until

  def repeat_until=(value)
    @repeat_until = if value.is_a?(String)
                      begin
                        Date.parse(value)
                      rescue ArgumentError
                        nil
                      end
                    else
                      value
                    end
  end

  # Callbacks
  before_validation :generate_checkin_passcode, if: :should_generate_passcode?
  after_create :link_to_matching_recurring_excuses

  # Scopes for filtering
  scope :upcoming, -> { where(date: Time.zone.today..).order(:date) }
  scope :past, -> { where(date: ...Time.zone.today).order(date: :desc) }

  # Validation to ensure end_time is after date's start time
  def end_time_after_start_time
    return if end_time.blank? || date.blank?

    return unless end_time < date

    errors.add(:end_time, 'must be after the start time')
  end

  # Method to find overlapping events
  def overlapping_events
    return Event.none if date.blank? || end_time.blank?

    Event.where.not(id: id)
      .where('date < ? AND end_time > ?', end_time, date)
  end

  # Method to get attendance stats for this event
  def attendance_stats
    total = attendances.count
    present_count = attendances.present.count
    absent_count = attendances.absent.count
    excused_count = attendances.excused.count
    tardy_count = attendances.tardy.count

    # For attendance percentage, tardies count as present
    present_with_tardy_count = present_count + tardy_count

    {
      total: total,
      present: present_count,
      absent: absent_count,
      excused: excused_count,
      tardy: tardy_count,
      present_percentage: total.positive? ? ((present_with_tardy_count.to_f / total) * 100).round(1) : 0,
    }
  end

  # Return approved excuses for this event
  def approved_excuses
    excuses.approved
  end

  # Method to get count of approved excuses
  delegate :count, to: :approved_excuses, prefix: true

  # Check if a given user has an approved excuse for this event
  def approved_excuse_for_user?(user)
    approved_excuses.exists?(member_id: user.id)
  end
  alias user_has_approved_excuse? approved_excuse_for_user?

  # Method to get users with approved excuses
  def users_with_approved_excuses
    User.joins(excuses: :events)
      .where(events: { id: id }, excuses: { status: 'approved' })
      .distinct
  end

  # Self-checkin methods
  def self_checkin_available?
    return false unless allow_self_checkin?
    return false if date.blank? || end_time.blank?

    current_time = Time.current
    checkin_start = date.in_time_zone - 10.minutes
    checkin_end = end_time.in_time_zone + 10.minutes

    current_time.between?(checkin_start, checkin_end)
  end

  # Helper method to check self-checkin window status (for debugging)
  def self_checkin_window_info
    return { available: false, reason: 'Self check-in not enabled' } unless allow_self_checkin?
    return { available: false, reason: 'Missing date or end_time' } if date.blank? || end_time.blank?

    current_time = Time.current
    checkin_start = date.in_time_zone - 10.minutes
    checkin_end = end_time.in_time_zone + 10.minutes

    {
      available: current_time.between?(checkin_start, checkin_end),
      current_time: current_time,
      checkin_start: checkin_start,
      checkin_end: checkin_end,
      minutes_until_start: ((checkin_start - current_time) / 60).round,
      minutes_until_end: ((checkin_end - current_time) / 60).round,
    }
  end

  def verify_passcode(input_passcode)
    checkin_passcode.present? && checkin_passcode == input_passcode.to_s.strip
  end

  # convert event to iCalendar format
  def to_ical_event
    event = Icalendar::Event.new
    event.dtstart = Icalendar::Values::DateTime.new(date.in_time_zone("America/Chicago"))
    event.dtend   = Icalendar::Values::DateTime.new(end_time.in_time_zone("America/Chicago"))
    event.summary = title
    event.description = description
    event.location = location
    host = Rails.application.config.action_controller.default_url_options&.fetch(:host, 'localhost:3000')
    event.url = Rails.application.routes.url_helpers.internal_event_url(self, host: host)
    event.uid = "event-#{id}@singing-cadets-tamu"
    event.dtstamp = Time.current
    event.created = created_at
    event.last_modified = updated_at
    event
  end

  # for RSS feed item
  def to_rss_item
    {
      title: title,
      description: rss_description,
      pub_date: created_at,
      link: Rails.application.routes.url_helpers.internal_event_url(self, host: 'localhost:3000'),
      guid: "event-#{id}",
    }
  end

  private

  def should_generate_passcode?
    allow_self_checkin? && checkin_passcode.blank?
  end

  def generate_checkin_passcode
    self.checkin_passcode = rand(1000..9999).to_s
  end

  before_destroy :destroy_related_excuses

  def destroy_related_excuses
    # Only destroy excuses that are exclusively linked to this event
    excuses.each do |excuse|
      excuse.destroy if excuse.events.count == 1 # only linked to this event
    end
  end

  def link_to_matching_recurring_excuses
    Excuse.where(recurring: true)
          .where('start_date <= ? AND end_date >= ?', date.to_date, date.to_date)
          .find_each do |excuse|
      next unless excuse.recurring_days_array.include?(date.wday)
      next unless matches_recurring_time_window?(excuse)
      next if excuse.events.exists?(id: id)

      excuse.events << self

      next unless excuse.status == 'approved'

      Attendance.find_or_initialize_by(event_id: id, user_id: excuse.member_id).tap do |a|
        a.status = 'excused'
        a.note = "Excused - Approved excuse ##{excuse.id}"
        a.save
      end
    end
  end

  def matches_recurring_time_window?(excuse)
    return true if excuse.recurring_start_time.blank? || excuse.recurring_end_time.blank?

    start_mins = excuse.recurring_start_time.hour * 60 + excuse.recurring_start_time.min
    end_mins = excuse.recurring_end_time.hour * 60 + excuse.recurring_end_time.min
    event_mins = date.hour * 60 + date.min

    event_mins >= start_mins && event_mins <= end_mins
  end

  def rss_description
    parts = []
    parts << "Date: #{date.strftime('%B %d, %Y at %I:%M %p')}"
    parts << "End Time: #{end_time.strftime('%I:%M %p')}"
    parts << "Location: #{location}" if respond_to?(:location) && location.present?
    parts << description if respond_to?(:description) && description.present?
    parts.join("\n")
  end
end
