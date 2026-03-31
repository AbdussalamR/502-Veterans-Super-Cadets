class PageContent < ApplicationRecord
  PAGES = %w[home contact auditions].freeze

  validates :page_name, presence: true, inclusion: { in: PAGES }
  validates :content_key, presence: true
  validates :content_key, uniqueness: { scope: %i[page_name is_draft] }

  scope :published, -> { where(is_draft: false) }
  scope :drafts,    -> { where(is_draft: true) }
  scope :for_page,  ->(page) { where(page_name: page) }

  def self.get(page, key, draft: false)
    find_by(page_name: page, content_key: key, is_draft: draft)&.content_value
  end

  def self.set(page, key, value, draft: true)
    record = find_or_initialize_by(page_name: page, content_key: key, is_draft: draft)
    record.content_value = value
    record.save!
  end

  def self.has_drafts?(page) # rubocop:disable Naming/PredicatePrefix
    drafts.for_page(page).exists?
  end

  def self.publish_page!(page)
    transaction do
      published.for_page(page).destroy_all
      drafts.for_page(page).update_all(is_draft: false)
    end
  end

  def self.discard_drafts!(page)
    drafts.for_page(page).destroy_all
  end
end
