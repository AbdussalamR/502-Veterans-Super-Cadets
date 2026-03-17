# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Clear out any previous seed users if they exist
# User.where(email: "email to delete").destroy_all

# REPLACE email with your actual Gmail address
User.find_or_create_by!(email: "deniza.telci@tamu.edu") do |user|
  user.full_name = "Your Name" # You can put your real name here
  user.uid = "12345" # This is a placeholder; Google will update it when you log in
  user.provider = "google_oauth2"
  user.role = "super_admin"
  user.approval_status = "approved"
end

# --- Test data for recurring excuses ---

# Officer user
User.find_or_create_by!(email: "officer@tamu.edu") do |user|
  user.full_name = "Officer Jones"
  user.uid = "officer1"
  user.provider = "google_oauth2"
  user.role = "officer"
  user.approval_status = "approved"
end

# Regular member
member = User.find_or_create_by!(email: "member@tamu.edu") do |user|
  user.full_name = "Cadet Smith"
  user.uid = "member1"
  user.provider = "google_oauth2"
  user.role = "user"
  user.approval_status = "approved"
end

# Create events spanning several weeks on Mon/Wed/Fri
# Covers March 2–27, 2026 (4 weeks of Mon/Wed/Fri rehearsals)
base_monday = Date.new(2026, 3, 2) # a Monday
events = []
4.times do |week|
  [0, 2, 4].each do |day_offset| # Mon, Wed, Fri
    event_date = base_monday + (week * 7) + day_offset
    events << Event.find_or_create_by!(
      title: "Rehearsal",
      date: event_date.to_datetime.change(hour: 17, min: 0)
    ) do |e|
      e.end_time = event_date.to_datetime.change(hour: 18, min: 30)
      e.location = "Hullabaloo Hall"
      e.description = "Weekly rehearsal"
    end
  end
end

# A few Tuesday events (should NOT match a Mon/Wed recurring excuse)
2.times do |week|
  tue_date = base_monday + (week * 7) + 1
  Event.find_or_create_by!(
    title: "Section Meeting",
    date: tue_date.to_datetime.change(hour: 12, min: 0)
  ) do |e|
    e.end_time = tue_date.to_datetime.change(hour: 13, min: 0)
    e.location = "MSC"
    e.description = "Section leader meeting"
  end
end

# A Saturday performance (tests day filtering)
Event.find_or_create_by!(
  title: "Spring Performance",
  date: Date.new(2026, 3, 14).to_datetime.change(hour: 19, min: 0)
) do |e|
  e.end_time = Date.new(2026, 3, 14).to_datetime.change(hour: 21, min: 0)
  e.location = "Rudder Auditorium"
  e.description = "Spring concert"
end

# --- Sample excuses ---

# 1) A regular (non-recurring) excuse from the member
regular_excuse = Excuse.find_or_create_by!(
  member: member,
  reason: "Doctor appointment",
  recurring: false
) do |e|
  e.status = "pending"
  e.submission_date = Time.current
  e.proof_link = "https://example.com/doctors-note"
end
regular_excuse.events = [events.first] if regular_excuse.events.empty?

# 2) A recurring excuse: every Monday for March 2026
recurring_excuse = Excuse.find_or_create_by!(
  member: member,
  reason: "Weekly physical therapy - recurring Monday conflict",
  recurring: true
) do |e|
  e.status = "pending"
  e.submission_date = Time.current
  e.proof_link = "https://example.com/pt-schedule"
  e.start_date = Date.new(2026, 3, 2)
  e.end_date = Date.new(2026, 3, 27)
  e.recurring_days = "1" # Monday
  e.recurring_start_time = Time.zone.parse('08:00')
  e.recurring_end_time = Time.zone.parse('23:59')
  e.frequency = "weekly"
end
if recurring_excuse.events.empty?
  matching = events.select { |ev| ev.date.wday == 1 } # Mondays
  matching.each { |ev| recurring_excuse.events << ev }
end

# 3) A recurring excuse already approved (for testing show view badges)
approved_recurring = Excuse.find_or_create_by!(
  member: member,
  reason: "Class conflict every Wed & Fri through mid-March",
  recurring: true
) do |e|
  e.status = "approved"
  e.submission_date = 1.week.ago
  e.reviewed_date = 3.days.ago
  e.proof_link = "https://example.com/class-schedule"
  e.start_date = Date.new(2026, 3, 2)
  e.end_date = Date.new(2026, 3, 13)
  e.recurring_days = "3,5" # Wed, Fri
  e.recurring_start_time = Time.zone.parse('08:00')
  e.recurring_end_time = Time.zone.parse('23:59')
  e.frequency = "weekly"
end
if approved_recurring.events.empty?
  matching = events.select { |ev| [3, 5].include?(ev.date.wday) && ev.date <= Date.new(2026, 3, 13) }
  matching.each { |ev| approved_recurring.events << ev }
end

puts "Seeded:"
puts "  - #{User.count} users (admin, officer, member)"
puts "  - #{Event.count} events (Mon/Wed/Fri rehearsals + Tue meetings + Sat performance)"
puts "  - #{Excuse.count} excuses (1 regular, 2 recurring)"
puts "  - Recurring excuse ##{recurring_excuse.id}: Mondays, #{recurring_excuse.events.count} events matched"
puts "  - Recurring excuse ##{approved_recurring.id}: Wed+Fri, #{approved_recurring.events.count} events matched (approved)"
puts ""
puts "Login as member@tamu.edu to test submitting recurring excuses"
puts "Login as officer@tamu.edu to test provisional approval"
puts "Login as deniza.telci@tamu.edu (super_admin) to finalize"
