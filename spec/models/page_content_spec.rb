# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PageContent, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      pc = build(:page_content)
      expect(pc).to be_valid
    end

    it 'is invalid without page_name' do
      pc = build(:page_content, page_name: nil)
      expect(pc).not_to be_valid
    end

    it 'is invalid with an unrecognised page_name' do
      pc = build(:page_content, page_name: 'unknown_page')
      expect(pc).not_to be_valid
    end

    it 'is invalid without content_key' do
      pc = build(:page_content, content_key: nil)
      expect(pc).not_to be_valid
    end

    it 'enforces uniqueness of content_key scoped to page_name and is_draft' do
      create(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: false)
      duplicate = build(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: false)
      expect(duplicate).not_to be_valid
    end

    it 'allows same key as draft and published simultaneously' do
      create(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: false)
      draft = build(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: true)
      expect(draft).to be_valid
    end
  end

  describe '.get' do
    it 'returns nil when no record exists' do
      expect(PageContent.get('home', 'hero_title')).to be_nil
    end

    it 'returns the published value by default' do
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Published Title', is_draft: false)
      expect(PageContent.get('home', 'hero_title')).to eq('Published Title')
    end

    it 'returns the draft value when draft: true' do
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Draft Title', is_draft: true)
      expect(PageContent.get('home', 'hero_title', draft: true)).to eq('Draft Title')
    end

    it 'does not return draft content when draft: false' do
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Draft Title', is_draft: true)
      expect(PageContent.get('home', 'hero_title', draft: false)).to be_nil
    end
  end

  describe '.set' do
    it 'creates a new draft record' do
      expect {
        PageContent.set('home', 'hero_title', 'New Title', draft: true)
      }.to change(PageContent, :count).by(1)
    end

    it 'updates an existing record with the same key/page/draft' do
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Old', is_draft: true)
      expect {
        PageContent.set('home', 'hero_title', 'Updated', draft: true)
      }.not_to change(PageContent, :count)
      expect(PageContent.get('home', 'hero_title', draft: true)).to eq('Updated')
    end
  end

  describe '.has_drafts?' do
    it 'returns false when no drafts exist' do
      create(:page_content, page_name: 'home', is_draft: false)
      expect(PageContent.has_drafts?('home')).to be false
    end

    it 'returns true when drafts exist' do
      create(:page_content, page_name: 'home', is_draft: true)
      expect(PageContent.has_drafts?('home')).to be true
    end
  end

  describe '.publish_page!' do
    it 'converts all drafts to published' do
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Draft Value', is_draft: true)

      expect { PageContent.publish_page!('home') }
        .to change { PageContent.published.for_page('home').count }.by(1)
        .and change { PageContent.drafts.for_page('home').count }.by(-1)
    end

    it 'removes old published records before publishing drafts' do
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Old Published', is_draft: false)
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'New Draft', is_draft: true)

      PageContent.publish_page!('home')

      expect(PageContent.get('home', 'hero_title')).to eq('New Draft')
      expect(PageContent.published.for_page('home').count).to eq(1)
    end

    it 'does not affect other pages' do
      create(:page_content, page_name: 'contact', content_key: 'email',
             content_value: 'contact@example.com', is_draft: true)
      create(:page_content, page_name: 'home', content_key: 'hero_title',
             content_value: 'Home Draft', is_draft: true)

      PageContent.publish_page!('home')

      expect(PageContent.drafts.for_page('contact').count).to eq(1)
    end
  end

  describe '.discard_drafts!' do
    it 'removes all drafts for the page' do
      create(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: true)
      create(:page_content, page_name: 'home', content_key: 'about_text', is_draft: true)

      expect { PageContent.discard_drafts!('home') }
        .to change { PageContent.drafts.for_page('home').count }.by(-2)
    end

    it 'does not remove published records' do
      create(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: false)
      create(:page_content, page_name: 'home', content_key: 'hero_title', is_draft: true)

      PageContent.discard_drafts!('home')

      expect(PageContent.published.for_page('home').count).to eq(1)
    end
  end
end
