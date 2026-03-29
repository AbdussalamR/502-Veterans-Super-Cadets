class ContactMessage < ApplicationRecord
  validates :name,    presence: true
  validates :email,   presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true

  scope :unread,  -> { where(read_at: nil) }
  scope :recent,  -> { order(created_at: :desc) }

  def read!
    update!(read_at: Time.current)
  end

  def unread?
    read_at.nil?
  end
end
