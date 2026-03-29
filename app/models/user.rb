# frozen_string_literal: true

class User < ApplicationRecord
  include LoggableModel
  
  devise :omniauthable, omniauth_providers: [:google_oauth2]
  attr_accessor :just_registered_via_google

  # Role constants
  ROLES = %w[user officer super_admin].freeze
  APPROVAL_STATUSES = %w[pending approved rejected].freeze

  # Validations (wrapped in begin/rescue to handle missing table during migrations)
  begin
    validates :email, presence: true, uniqueness: true,
                      format: { with: URI::MailTo::EMAIL_REGEXP, message: 'is not a valid email address' }
    validates :full_name, presence: true
    validates :uid, presence: true
    validates :role, inclusion: { in: ROLES }
    validates :approval_status, inclusion: { in: APPROVAL_STATUSES }, allow_nil: true
  rescue ActiveRecord::StatementInvalid
    # Table doesn't exist yet during migrations - skip validations
  end

  # Associations (wrapped to handle missing table during migrations)
  begin
    has_many :attendances, dependent: :destroy
    has_many :attended_events, through: :attendances, source: :event
    has_many :excuses, foreign_key: :member_id, dependent: :destroy
    has_many :received_demerits, class_name: 'Demerit', foreign_key: 'member_id', dependent: :destroy
    has_many :given_demerits, class_name: 'Demerit', foreign_key: 'given_by_id', dependent: :nullify
    has_many :admin_alerts, dependent: :destroy

    # Scopes
    scope :officers, -> { where(role: 'officer') }
    scope :super_admins, -> { where(role: 'super_admin') }
    scope :admins, -> { where(role: %w[officer super_admin]) }

    # Approval scopes
    scope :pending, -> { where(approval_status: 'pending') }
    scope :approved, -> { where(approval_status: 'approved') }
    scope :rejected, -> { where(approval_status: 'rejected') }
  rescue ActiveRecord::StatementInvalid
    # Table doesn't exist yet during migrations - skip associations
  end

  # New associations for excuse reviewers
  has_many :reviewers_to_excuses,
    class_name: "ReviewersToExcuse",
    foreign_key: :reviewer_id,
    inverse_of: :reviewer,
    dependent: :destroy

  has_many :reviewed_excuses,
    through: :reviewers_to_excuses,
    source: :excuse

  # Role check methods
  def user?
    role == 'user'
  end

  def officer?
    role == 'officer'
  end

  def super_admin?
    role == 'super_admin'
  end

  def admin?
    officer? || super_admin?
  end

  # Display name for role (for UI purposes)
  def role_display_name
    case role
    when 'user'
      'Member'
    when 'super_admin'
      'Director'
    when 'officer'
      'Officer'
    else
      role.humanize
    end
  end

  def can_promote_users?
    super_admin?
  end

  def can_perform_admin_actions?
    admin?
  end

  # Calculate total absences for a user following the 0.33, 0.66, 1, 1.33, 1.66, 2... pattern
  def total_absence_points
    # Count regular absences (1 point each)
    regular_absences = attendances.absent.count
    
    # Count tardies (0.33 points each, rounds to 1.0 after 3 tardies)
    tardy_count = attendances.tardy.count
    tardy_points = tardy_count * 0.33
    
    # Round tardy points: if result is 0.99 (3 tardies), round to 1.0
    # Check if within 0.01 of a whole number (inclusive)
    rounded_tardy = tardy_points.round(2)
    whole_part = rounded_tardy.round
    if (rounded_tardy - whole_part).abs <= 0.01
      tardy_points = whole_part.to_f
    else
      tardy_points = rounded_tardy
    end
    
    # Sum discipline points using the absence_points method for each discipline record
    discipline_points = received_demerits.sum { |demerit| demerit.absence_points }
    
    # Calculate total: absences + (tardies * 0.33, rounded) + sum of discipline points
    total = regular_absences + tardy_points + discipline_points
    
    # Round final total to 2 decimal places
    total.round(2)
  end

  # Method to promote a user to officer (only super_admins can do this)
  def promote_to_officer!(promoted_by:)
    raise 'Only super admins can promote users' unless promoted_by.super_admin?
    raise 'User is already an officer or higher' if officer? || super_admin?

    update!(role: 'officer')
    log_model_action('promoted_to_officer', { 
      promoted_by_id: promoted_by.id,
      promoted_by_email: promoted_by.email,
      previous_role: 'user',
      new_role: 'officer'
    })
  end

  # Method to promote a user to super admin (only super_admins can do this)
  def promote_to_super_admin!(promoted_by:)
    raise 'Only super admins can promote users' unless promoted_by.super_admin?
    raise 'User is already a super admin' if super_admin?

    previous_role = role
    update!(role: 'super_admin')
    log_model_action('promoted_to_super_admin', { 
      promoted_by_id: promoted_by.id,
      promoted_by_email: promoted_by.email,
      previous_role: previous_role,
      new_role: 'super_admin'
    })
  end

  # Method to demote to user (only super_admins can do this)
  def demote_to_user!(demoted_by:)
    raise 'Only super admins can demote users' unless demoted_by.super_admin?
    raise 'Cannot demote yourself' if self == demoted_by
    raise 'User is already a regular user' if user?

    previous_role = role
    update!(role: 'user')
    log_model_action('demoted_to_user', { 
      demoted_by_id: demoted_by.id,
      demoted_by_email: demoted_by.email,
      previous_role: previous_role,
      new_role: 'user'
    })
  end

  # Method to demote to officer (only super_admins can do this)
  def demote_to_officer!(demoted_by:)
    raise 'Only super admins can demote users' unless demoted_by.super_admin?
    raise 'Cannot demote yourself' if self == demoted_by
    raise 'User is not a super admin' unless super_admin?

    update!(role: 'officer')
    log_model_action('demoted_to_officer', { 
      demoted_by_id: demoted_by.id,
      demoted_by_email: demoted_by.email,
      previous_role: 'super_admin',
      new_role: 'officer'
    })
  end

  # Approval status methods
  def pending?
    approval_status == 'pending'
  end

  def approved?
    approval_status == 'approved'
  end

  def rejected?
    approval_status == 'rejected'
  end

  # Method to approve a user's registration (only officers and super_admins can do this)
  def approve!(approved_by:)
    raise 'Only officers or super admins can approve users' unless approved_by.admin?
    raise 'User is already approved' if approved?

    update!(approval_status: 'approved')
    log_model_action('registration_approved', { 
      approved_by_id: approved_by.id,
      approved_by_email: approved_by.email,
      previous_status: 'pending',
      new_status: 'approved'
    })
  end

  # Method to reject a user's registration (only officers and super_admins can do this)
  def reject!(rejected_by:)
    raise 'Only officers or super admins can reject users' unless rejected_by.admin?
    raise 'User is already rejected' if rejected?

    update!(approval_status: 'rejected')
    log_model_action('registration_rejected', { 
      rejected_by_id: rejected_by.id,
      rejected_by_email: rejected_by.email,
      previous_status: 'pending',
      new_status: 'rejected'
    })
  end

  # Automatically generates a secure, unique token before the record is created.
  # This token is used to provide a private, unguessable calendar subscription URL
  # (e.g., for .ics feeds) without requiring user authentication.
  before_create :generate_calendar_token

  def generate_calendar_token
    self.calendar_token = SecureRandom.hex(20)
  end

  # Override from_google method to set default approval_status
  def self.from_google(email:, full_name:, uid:, avatar_url:)
    user = find_or_initialize_by(email: email)

    if user.new_record?
      # Check if this email is in the super admin list
      super_admin_emails = ENV['SUPER_ADMIN_EMAILS']&.split(',')&.map(&:strip) || []

      # Only allow @tamu.edu emails for new accounts (existing accounts are unaffected)
      unless email.end_with?('@tamu.edu') || super_admin_emails.include?(email)
        Rails.logger.warn({ action: 'oauth_sign_in_blocked', reason: 'non_tamu_email', email: email, timestamp: Time.current.iso8601 }.to_json)
        return nil
      end

      initial_role = super_admin_emails.include?(email) ? 'super_admin' : 'user'
      initial_approval = super_admin_emails.include?(email) ? 'approved' : 'pending'

      user.assign_attributes(
        uid: uid,
        full_name: full_name,
        avatar_url: avatar_url,
        provider: 'google_oauth2',
        role: initial_role,
        approval_status: initial_approval
      )
      user.save!
      user.just_registered_via_google = true
      
      # Log new user creation
      Rails.logger.info({
        action: 'new_user_created',
        model: 'User',
        record_id: user.id,
        email: user.email,
        full_name: user.full_name,
        role: initial_role,
        approval_status: initial_approval,
        timestamp: Time.current.iso8601
      }.to_json)
    else
      # Update existing user's info but preserve their role and approval_status
      user.update!(
        uid: uid,
        full_name: full_name,
        avatar_url: avatar_url,
        provider: 'google_oauth2'
      )
    end

    user
  end

  belongs_to :section, optional: true

  # Helper to check if this user is a leader of their section
  def section_leader?
    officer? && section.present?
  end

  def email_deliverable?
    email_notifications_enabled? && email.present?
  end
end
