# frozen_string_literal: true

class ApplicationSetting < ApplicationRecord
  validates :reminder_hours_before, presence: true,
                                    numericality: { only_integer: true, greater_than: 0 }

  # Always operate on the single settings row.
  def self.instance
    first_or_create!(reminder_hours_before: 24)
  end
end
