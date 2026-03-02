# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Section, type: :model do
  describe 'validations' do
    it 'is valid with a name' do
      section = Section.new(name: 'Tenor 1')
      expect(section).to be_valid
    end

    it 'requires a name' do
      section = Section.new(name: nil)
      expect(section).not_to be_valid
      expect(section.errors[:name]).to include("can't be blank")
    end

    it 'requires a unique name' do
      Section.create!(name: 'Tenor 1')
      duplicate = Section.new(name: 'Tenor 1')
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it 'has many users' do
      assoc = Section.reflect_on_association(:users)
      expect(assoc.macro).to eq(:has_many)
    end
  end

  describe '#section_leader' do
    let(:section) { create(:section, name: 'Tenor 1') }

    it 'returns the officer assigned to the section' do
      officer = create(:user, :officer, section: section)
      create(:user, section: section) # regular member

      expect(section.section_leader).to eq(officer)
    end

    it 'returns nil when no officer is assigned' do
      create(:user, section: section) # regular member only

      expect(section.section_leader).to be_nil
    end
  end
end
