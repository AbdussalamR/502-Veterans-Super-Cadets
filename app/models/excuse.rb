class Excuse < ApplicationRecord
  belongs_to :member, class_name: 'User'

  # proof is now a URL/link instead of an uploaded file
  # has_one_attached :proof  -- removed

  # New join associations for many-to-many
  has_many :events_to_excuses,
    class_name: "EventsToExcuse",
    foreign_key: :excuse_id,
    dependent: :destroy,
    inverse_of: :excuse,
    autosave: true
  has_many :events, through: :events_to_excuses

  has_many :reviewers_to_excuses,
    class_name: "ReviewersToExcuse",
    foreign_key: :excuse_id,
    dependent: :destroy,
    inverse_of: :excuse,
    autosave: true
  has_many :reviewers, through: :reviewers_to_excuses, source: :reviewer

  validates :reason, presence: true

  # proof_link is now required and must look like a URL
  validates :proof_link, presence: true
  validates :proof_link, 
format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: false

  # Return the primary/representative event for this excuse.
  # Use a deterministic ordering (by date) so `excuse.event` returns the same
  # event everywhere (index, show, etc.).
  def event
    # If events are already loaded into memory (e.g. assigned on a new record),
    # use the in-memory objects (deterministically ordered by date).
    if events.loaded?
      events.to_a.compact.sort_by { |e| e.date || Time.zone.at(0) }.first
    else
      events.order(date: :asc).first
    end
  end

  def event=(event_or_id)
    ev = event_or_id.is_a?(Event) ? event_or_id : Event.find_by(id: event_or_id)
    self.events = ev ? [ev] : []
  end

  def event_id
    event&.id
  end

  def event_id=(id)
    if id.present?
      ev = Event.find_by(id: id)
      self.events = ev ? [ev] : []
    else
      self.events = []
    end
  end

  def reviewed_by
    reviewers.first
  end

  def reviewed_by=(user_or_id)
    user = user_or_id.is_a?(User) ? user_or_id : User.find_by(id: user_or_id)
    self.reviewers = user ? [user] : []
  end

  def reviewed_by_id
    reviewed_by&.id
  end

  def reviewed_by_id=(id)
    if id.present?
      user = User.find_by(id: id)
      self.reviewers = user ? [user] : []
    else
      self.reviewers = []
    end
  end

  # Add a reviewer without replacing existing reviewers.
  # Creates a ReviewersToExcuse join record with timestamps (so you can show who reviewed when).
  # Returns the join record (or nil if user was nil or already a reviewer).
  def add_reviewer(user_or_id)
    user = user_or_id.is_a?(User) ? user_or_id : User.find_by(id: user_or_id)
    return nil unless user

    # Do nothing if already reviewed by this user
    return nil if reviewers.exists?(id: user.id)

    reviewers_to_excuses.create(reviewer: user)
  end

  # Helper to get reviewer join records in chronological order.
  # Each element is a ReviewersToExcuse record (has reviewer and created_at).
  def reviewer_entries
    reviewers_to_excuses.includes(:reviewer).order(created_at: :asc)
  end

  # Scopes for filtering by status
  scope :approved, -> { where(status: 'approved') }
  scope :pending, -> { where(status: 'pending') }
  scope :denied, -> { where(status: 'denied') }

  # New scope: processed by officers but awaiting admin finalization
  scope :pending_admin_approval, -> { where(status: 'pending').where.not(officer_status: nil) }

  # Pending (no officer processing yet)
  scope :pending_unprocessed, -> { where(status: 'pending', officer_status: nil) }

  # Adjusted helper for reviewer entries already exists (reviewer_entries).
  # Add convenience helpers:

  def provisional_decision
    officer_status
  end

  def provisional_decision_time
    officer_reviewed_at
  end

  # Called when an officer takes a provisional action (approve/deny).
  def set_officer_decision(user_or_id, decision)
    user = user_or_id.is_a?(User) ? user_or_id : User.find_by(id: user_or_id)
    return false unless user && %w[approved denied].include?(decision)

    # record provisional decision on the excuse
    self.officer_status = decision
    self.officer_reviewed_at = Time.current

    # add the reviewer entry (if not already present)
    add_reviewer(user)

    save
  end

  # Called when an admin finalizes the decision
  def finalize_by_admin(admin_user_or_id, final_decision)
    admin = admin_user_or_id.is_a?(User) ? admin_user_or_id : User.find_by(id: admin_user_or_id)
    return false unless admin && %w[approved denied].include?(final_decision)

    old_status = status
    self.status = final_decision
    # Optionally set reviewed_date for the finalization
    self.reviewed_date = Time.current if self.reviewed_date.blank?

    # record that the admin reviewed it
    add_reviewer(admin)

    save
  end
end