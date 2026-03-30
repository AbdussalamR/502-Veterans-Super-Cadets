class MediaPhoto < ApplicationRecord
  has_one_attached :image

  PAGES = %w[home media].freeze

  validates :page_name, presence: true, inclusion: { in: PAGES }
  validate :image_must_be_attached

  scope :for_page,       ->(page) { where(page_name: page) }
  scope :ordered,        -> { order(:position, :id) }
  scope :published_only, -> { where(published: true) }

  def self.next_position(page)
    for_page(page).maximum(:position).to_i + 1
  end

  private

  def image_must_be_attached
    errors.add(:image, "must be attached") unless image.attached?
  end
end
