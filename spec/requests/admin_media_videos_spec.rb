# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::MediaVideos', type: :request do
  let(:admin)        { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  let(:valid_url)    { 'https://www.youtube.com/watch?v=dQw4w9WgXcQ' }

  before { sign_in admin }

  describe 'POST /admin/media_videos' do
    context 'with a valid YouTube URL' do
      it 'creates a new MediaVideo as unpublished' do
        expect do
          post admin_media_videos_path, params: { youtube_url: valid_url, title: 'Rickroll' }
        end.to change(MediaVideo, :count).by(1)

        video = MediaVideo.last
        expect(video.published).to be false
        expect(video.youtube_id).to eq('dQw4w9WgXcQ')
        expect(video.title).to eq('Rickroll')
      end

      it 'redirects to the media tab with an instructional notice' do
        post admin_media_videos_path, params: { youtube_url: valid_url }
        expect(response).to redirect_to(admin_website_path(tab: 'media'))
        expect(flash[:notice]).to include('Click Publish')
      end
    end

    context 'with an invalid URL' do
      it 'does not create a record' do
        expect do
          post admin_media_videos_path, params: { youtube_url: 'https://vimeo.com/123' }
        end.not_to change(MediaVideo, :count)
        expect(flash[:alert]).to be_present
      end
    end

    context 'as a non-admin' do
      before { sign_in regular_user }

      it 'redirects away without creating' do
        expect do
          post admin_media_videos_path, params: { youtube_url: valid_url }
        end.not_to change(MediaVideo, :count)
        expect(response).to redirect_to(internal_events_path)
      end
    end
  end

  describe 'PATCH /admin/media_videos/:id/publish' do
    let!(:video) { create(:media_video, published: false) }

    it 'sets published to true' do
      patch publish_admin_media_video_path(video)
      expect(video.reload.published).to be true
    end

    it 'redirects to the media tab with a notice' do
      patch publish_admin_media_video_path(video)
      expect(response).to redirect_to(admin_website_path(tab: 'media'))
      expect(flash[:notice]).to include('live')
    end

    it 'requires admin access' do
      sign_in regular_user
      patch publish_admin_media_video_path(video)
      expect(video.reload.published).to be false
    end
  end

  describe 'DELETE /admin/media_videos/:id' do
    let!(:video) { create(:media_video) }

    it 'deletes the video' do
      expect do
        delete admin_media_video_path(video)
      end.to change(MediaVideo, :count).by(-1)
    end

    it 'redirects to the media tab' do
      delete admin_media_video_path(video)
      expect(response).to redirect_to(admin_website_path(tab: 'media'))
    end

    it 'requires admin access' do
      sign_in regular_user
      expect do
        delete admin_media_video_path(video)
      end.not_to change(MediaVideo, :count)
    end
  end
end
