# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaVideo, type: :model do
  describe 'validations' do
    it 'is valid with a standard YouTube watch URL' do
      video = build(:media_video)
      expect(video).to be_valid
    end

    it 'is invalid without a youtube_url' do
      video = build(:media_video, youtube_url: nil)
      expect(video).not_to be_valid
      expect(video.errors[:youtube_url]).to be_present
    end

    it 'is invalid with a non-YouTube URL' do
      video = build(:media_video, youtube_url: 'https://vimeo.com/123456', youtube_id: nil)
      expect(video).not_to be_valid
      expect(video.errors[:youtube_id]).to be_present
    end
  end

  describe 'YouTube ID extraction' do
    it 'extracts the ID from a standard watch URL' do
      video = build(:media_video, youtube_url: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ', youtube_id: nil)
      video.valid?
      expect(video.youtube_id).to eq('dQw4w9WgXcQ')
    end

    it 'extracts the ID from a shortened youtu.be URL' do
      video = build(:media_video, youtube_url: 'https://youtu.be/dQw4w9WgXcQ', youtube_id: nil)
      video.valid?
      expect(video.youtube_id).to eq('dQw4w9WgXcQ')
    end

    it 'extracts the ID from an embed URL' do
      video = build(:media_video, youtube_url: 'https://www.youtube.com/embed/dQw4w9WgXcQ', youtube_id: nil)
      video.valid?
      expect(video.youtube_id).to eq('dQw4w9WgXcQ')
    end

    it 'sets youtube_id to nil for a non-YouTube URL' do
      video = build(:media_video, youtube_url: 'https://example.com/video', youtube_id: nil)
      video.valid?
      expect(video.youtube_id).to be_nil
    end
  end

  describe '#embed_url' do
    it 'returns the correct YouTube embed URL' do
      video = build(:media_video, youtube_id: 'dQw4w9WgXcQ')
      expect(video.embed_url).to eq('https://www.youtube.com/embed/dQw4w9WgXcQ')
    end
  end

  describe '.next_position' do
    it 'returns 1 when no videos exist' do
      expect(MediaVideo.next_position).to eq(1)
    end

    it 'returns max position + 1' do
      create(:media_video, position: 3)
      expect(MediaVideo.next_position).to eq(4)
    end
  end

  describe 'scopes' do
    let!(:unpublished) { create(:media_video, published: false) }
    let!(:published)   { create(:media_video, :published, youtube_url: 'https://www.youtube.com/watch?v=ABCDEFGHIJK') }

    it '.published_only returns only published records' do
      expect(MediaVideo.published_only).to include(published)
      expect(MediaVideo.published_only).not_to include(unpublished)
    end
  end
end
