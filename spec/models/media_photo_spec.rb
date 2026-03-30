# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaPhoto, type: :model do
  describe 'validations' do
    it 'is valid with a page_name and attached image' do
      photo = build(:media_photo)
      expect(photo).to be_valid
    end

    it 'is invalid without a page_name' do
      photo = build(:media_photo, page_name: nil)
      expect(photo).not_to be_valid
    end

    it 'is invalid with an unrecognised page_name' do
      photo = build(:media_photo, page_name: 'unknown')
      expect(photo).not_to be_valid
    end

    it 'is invalid without an attached image' do
      photo = build(:media_photo)
      photo.image.detach if photo.image.attached?
      # Build a photo without attaching an image
      bare = MediaPhoto.new(page_name: 'media', caption: 'test', position: 1, published: false)
      expect(bare).not_to be_valid
      expect(bare.errors[:image]).to be_present
    end
  end

  describe '.next_position' do
    it 'returns 1 when no photos exist for the page' do
      expect(MediaPhoto.next_position('media')).to eq(1)
    end

    it 'returns max position + 1' do
      create(:media_photo, position: 5)
      expect(MediaPhoto.next_position('media')).to eq(6)
    end
  end

  describe 'scopes' do
    let!(:unpublished) { create(:media_photo, published: false) }
    let!(:published)   { create(:media_photo, :published) }

    it '.published_only returns only published records' do
      expect(MediaPhoto.published_only).to include(published)
      expect(MediaPhoto.published_only).not_to include(unpublished)
    end

    it '.for_page filters by page_name' do
      home_photo = create(:media_photo, :home)
      expect(MediaPhoto.for_page('home')).to include(home_photo)
      expect(MediaPhoto.for_page('media')).not_to include(home_photo)
    end

    it '.ordered sorts by position then id' do
      p2 = create(:media_photo, position: 20)
      p1 = create(:media_photo, position: 10)
      ids = MediaPhoto.ordered.map(&:id)
      expect(ids.index(p1.id)).to be < ids.index(p2.id)
    end
  end
end
