class Section < ApplicationRecord
  has_many :users
  validates :name, presence: true, uniqueness: true

  # Helper to find the officer in charge of this section
  def section_leader
    users.where(role: 'officer').first
  end
end