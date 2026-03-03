# frozen_string_literal: true

class Excuse < ApplicationRecord
  DAY_NAMES = %w[Sunday Monday Tuesday Wednesday Thursday Friday Saturday].freeze

  belongs_to :member, class_name: 'User'
  
  # Virtual attribute to capture multi-select event IDs from the single-mode form
  attr_accessor :manual_event_ids

  # Associations
  has_many :events_to_excuses, class_name: "EventsToExcuse", foreign_key: :excuse_id, dependent: :destroy
  has_many :events, through: :events_to_excuses
  has_many :reviewers_to_excuses, class_name: "ReviewersToExcuse", foreign_key: :excuse_id, dependent: :destroy
  has_many :reviewers, through: :reviewers_to_excuses, source: :reviewer

  # Validations
  validates :reason, :proof_link, presence: true
  validates :proof_link, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: false
  
  # STORY U3: Recurring validations (only required if recurring toggle is on)
  validates :start_date, :end_date, presence: true, if: :recurring?
  validates :recurring_days, presence: { message: "must have at least one day selected" }, if: :recurring?

  # Scopes
  scope :approved, -> { where(status: 'approved') }
  scope :pending,  -> { where(status: 'pending') }
  scope :denied,   -> { where(status: 'denied') }

  # Required by layouts/internal.html.erb for the Director's notification badge
  # Finds excuses that have been reviewed by an officer but not yet finalized by the Director
  scope :pending_admin_approval, -> { where(status: 'pending').where.not(officer_status: [nil, '']) }

  # Required by layouts/internal.html.erb for the Officer's notification badge
  # Finds excuses that haven't been touched yet by any Section Leader
  scope :pending_unprocessed, -> { where(status: 'Pending Section Leader Review') }

  # STORY A3 AC 1: Default status on creation
  # This ensures every excuse starts in the Section Leader's queue.
  before_validation :set_default_status, on: :create
  
  # Logic Hooks
  after_create :process_event_links
  after_save :sync_attendance_records, if: :saved_change_to_status?

  # --- Helpers for FactoryBot and Views ---

  # Setter for FactoryBot and Single-Event forms to link events easily
  def event=(event_or_id)
    ev = event_or_id.is_a?(Event) ? event_or_id : Event.find_by(id: event_or_id)
    self.events = ev ? [ev] : []
  end

  def event_id=(id)
    self.event = id if id.present?
  end

  def recurring?
    recurring
  end

  # Returns the earliest event (for views expecting a single representative event)
  def event
    events.order(date: :asc).first
  end

  # Converts "1,3,5" stored in DB to [1, 3, 5] for logic checks
  def recurring_days_array
    recurring_days.to_s.split(',').map(&:to_i)
  end

  # Returns "Monday, Wednesday" for UI display
  def recurring_day_names
    recurring_days_array.map { |d| DAY_NAMES[d] }.compact.join(', ')
  end

  def reviewer_entries
    reviewers_to_excuses.includes(:reviewer).order(created_at: :asc)
  end

  def has_future_events?
    events.where('date > ?', Time.current).exists?
  end

  # --- Business Logic ---

  # STORY U3: Links existing events matching the pattern immediately upon creation
  def process_event_links
    if recurring?
      # Find all events matching the day-of-week pattern within the date range
      self.events = find_matching_events
    elsif manual_event_ids.present?
      # Link specific events selected in the single-mode multi-select box
      self.event_ids = Array(manual_event_ids).reject(&:blank?)
    end
  end

  def find_matching_events
    return Event.none if start_date.blank? || end_date.blank? || recurring_days.blank?
    days = recurring_days_array
    Event.where(date: start_date.beginning_of_day..end_date.end_of_day).select do |event|
      days.include?(event.date.wday)
    end
  end

  # STORY A3 AC 5: Admin Approval (Step 2)
  # Finalizes the decision and triggers the attendance sync.
  def finalize_by_admin(admin, final_decision)
    return false unless %w[approved denied].include?(final_decision)
    self.status = final_decision
    self.reviewed_date = Time.current
    add_reviewer(admin)
    save
  end

  # STORY A3: Officer Provisional Decision (Step 1)
  # Records the Section Leader's recommendation without updating attendance yet.
  def set_officer_decision(officer, decision)
    return false unless %w[approved denied].include?(decision)
    self.officer_status = decision
    self.officer_reviewed_at = Time.current
    add_reviewer(officer)
    save
  end

  def add_reviewer(user)
    return false if user.nil? || reviewers.exists?(id: user.id)
    reviewers_to_excuses.create(reviewer: user)
  end

  # Members can stop future occurrences of a recurring pattern
  def cancel_future_events!
    return unless recurring?
    events_to_excuses.joins(:event).where('events.date > ?', Time.current).destroy_all
  end

  private

  def set_default_status
    # STORY A3 AC 1: Specific requirement for default status string
    self.status ||= 'Pending Section Leader Review'
  end

  # Automatically updates Attendance table when status changes
  def sync_attendance_records
    if status == 'approved'
      # DIRECTOR APPROVED: Mark all linked events as Excused
      events.each do |event|
        Attendance.find_or_initialize_by(event_id: event.id, user_id: member_id).update!(
          status: 'excused',
          note: "Excused - Approved excuse ##{id}"
        )
      end
    elsif status_before_last_save == 'approved' && status != 'approved'
      # REVOKED: If status changed from approved to denied/pending, revert to absent
      events.each do |event|
        attn = Attendance.find_by(event_id: event.id, user_id: member_id)
        attn&.update!(status: 'absent', note: "Excuse ##{id} revoked/changed") if attn&.status == 'excused'
      end
    end
  end
end