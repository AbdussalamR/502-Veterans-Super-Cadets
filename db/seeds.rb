# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

# Clear out any previous seed users if they exist
User.where(email: "admin@test.com").destroy_all


# REPLACE email with  with your actual Gmail address
User.find_or_create_by!(email: "raheem05@tamu.edu") do |user|
  user.full_name = "Abdussalam Raheem" # You can put your real name here
  user.uid = "12345" # This is a placeholder; Google will update it when you log in
  user.provider = "google_oauth2"
  user.role = "super_admin"
  user.approval_status = "approved"
end

puts "Database seeded: raheem05@tamu.edu is now a Super Admin."
