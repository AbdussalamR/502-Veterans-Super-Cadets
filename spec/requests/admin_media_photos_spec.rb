# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::MediaPhotos', type: :request do
  let(:admin)        { create(:user, :super_admin) }
  let(:regular_user) { create(:user) }
  let(:test_image)   { fixture_file_upload(Rails.root.join('spec/fixtures/files/test_image.jpg'), 'image/jpeg') }

  before { sign_in admin }

  describe 'POST /admin/media_photos' do
    context 'with a valid image' do
      it 'creates a new MediaPhoto as unpublished' do
        expect {
          post admin_media_photos_path, params: { page_name: 'media', image: test_image, caption: 'Test' }
        }.to change(MediaPhoto, :count).by(1)

        photo = MediaPhoto.last
        expect(photo.published).to be false
        expect(photo.page_name).to eq('media')
      end

      it 'redirects to the media tab' do
        post admin_media_photos_path, params: { page_name: 'media', image: test_image }
        expect(response).to redirect_to(admin_website_path(tab: 'media'))
        expect(flash[:notice]).to include('Click Publish')
      end

      it 'replaces the existing home photo when page is home' do
        existing = create(:media_photo, :home)
        expect {
          post admin_media_photos_path, params: { page_name: 'home', image: test_image }
        }.not_to change(MediaPhoto, :count)
        expect { existing.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'without an image' do
      it 'does not create a record and shows an error' do
        expect {
          post admin_media_photos_path, params: { page_name: 'media' }
        }.not_to change(MediaPhoto, :count)
        expect(response).to redirect_to(admin_website_path(tab: 'media'))
        expect(flash[:alert]).to be_present
      end
    end

    context 'as a non-admin' do
      before { sign_in regular_user }

      it 'redirects away without creating' do
        expect {
          post admin_media_photos_path, params: { page_name: 'media', image: test_image }
        }.not_to change(MediaPhoto, :count)
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe 'PATCH /admin/media_photos/:id/publish' do
    let!(:photo) { create(:media_photo, published: false) }

    it 'sets published to true' do
      patch publish_admin_media_photo_path(photo)
      expect(photo.reload.published).to be true
    end

    it 'redirects to the media tab with a notice' do
      patch publish_admin_media_photo_path(photo)
      expect(response).to redirect_to(admin_website_path(tab: 'media'))
      expect(flash[:notice]).to include('live')
    end

    it 'requires admin access' do
      sign_in regular_user
      patch publish_admin_media_photo_path(photo)
      expect(photo.reload.published).to be false
      expect(response).to redirect_to(root_path)
    end
  end

  describe 'DELETE /admin/media_photos/:id' do
    let!(:photo) { create(:media_photo) }

    it 'deletes the photo' do
      expect {
        delete admin_media_photo_path(photo)
      }.to change(MediaPhoto, :count).by(-1)
    end

    it 'redirects to the media tab' do
      delete admin_media_photo_path(photo)
      expect(response).to redirect_to(admin_website_path(tab: 'media'))
    end

    it 'requires admin access' do
      sign_in regular_user
      expect {
        delete admin_media_photo_path(photo)
      }.not_to change(MediaPhoto, :count)
    end
  end
end
