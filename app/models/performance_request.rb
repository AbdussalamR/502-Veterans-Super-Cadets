# frozen_string_literal: true

class PerformanceRequest < ApplicationRecord
  validates :name,          presence: true
  validates :organization,  presence: true
  validates :contact_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP, message: "must be a valid email address" }
  validates :location,      presence: true
  validates :event_date,    presence: true
  validate  :event_date_must_be_in_future

  scope :pending,  -> { where(status: 'pending') }
  scope :reviewed, -> { where(status: 'reviewed') }
  scope :newest,   -> { order(created_at: :desc) }

  def pending?
    status == 'pending'
  end

  private

  def event_date_must_be_in_future
    return unless event_date.present?

    errors.add(:event_date, "must be a future date") if event_date < Date.today
  end
end
