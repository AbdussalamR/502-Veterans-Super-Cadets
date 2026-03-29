class MediaVideo < ApplicationRecord
  YOUTUBE_PATTERN = /(?:youtu\.be\/|youtube\.com\/(?:watch\?v=|embed\/|v\/))([a-zA-Z0-9_-]{11})/

  validates :youtube_url, presence: true
  validates :youtube_id, presence: { message: "could not be extracted — please use a standard YouTube URL" }
  validate  :youtube_url_format

  scope :ordered,        -> { order(:position, :id) }
  scope :published_only, -> { where(published: true) }

  before_validation :extract_youtube_id

  def embed_url
    "https://www.youtube.com/embed/#{youtube_id}"
  end

  def self.next_position
    maximum(:position).to_i + 1
  end

  private

  def extract_youtube_id
    return unless youtube_url.present?

    match = youtube_url.match(YOUTUBE_PATTERN)
    self.youtube_id = match ? match[1] : nil
  end

  def youtube_url_format
    return if youtube_url.blank?
    errors.add(:youtube_url, "must be a valid YouTube URL") unless youtube_url.match?(YOUTUBE_PATTERN)
  end
end
