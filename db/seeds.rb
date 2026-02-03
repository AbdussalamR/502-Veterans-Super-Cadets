# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

User.find_or_create_by!(email: "admin@test.com") do |user|
  user.full_name = "Development Admin"
  user.uid = "123456789"
  user.provider = "google_oauth2"
  user.role = "super_admin"
  user.approval_status = "approved"
end

puts "Created Development Admin: admin@test.com"
