# frozen_string_literal: true

class ApplicationSetting < ApplicationRecord
  validates :reminder_hours_before, presence: true,
                                    numericality: { only_integer: true, greater_than: 0 }
  validates :music_drive_url, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid URL" }, allow_blank: true

  # Always operate on the single settings row.
  def self.instance
    first_or_create!(reminder_hours_before: 24)
  end
end
