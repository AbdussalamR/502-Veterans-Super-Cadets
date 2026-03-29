# frozen_string_literal: true

FactoryBot.define do
  factory :application_setting do
    reminder_hours_before { 24 }
  end
end
