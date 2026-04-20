# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationSetting, type: :model do
  describe '.instance' do
    context 'when no row exists' do
      it 'creates a new row with default reminder_hours_before of 24' do
        expect { ApplicationSetting.instance }.to change(ApplicationSetting, :count).by(1)
        expect(ApplicationSetting.instance.reminder_hours_before).to eq(24)
      end
    end

    context 'when a row already exists' do
      it 'returns the existing row without creating a duplicate' do
        setting = ApplicationSetting.create!(reminder_hours_before: 48)
        expect(ApplicationSetting.instance).to eq(setting)
        expect(ApplicationSetting.count).to eq(1)
      end
    end
  end

  describe 'validations' do
    it 'is valid with a positive integer' do
      setting = build(:application_setting, reminder_hours_before: 12)
      expect(setting).to be_valid
    end

    describe 'music_drive_url' do
      it 'is valid when blank' do
        setting = build(:application_setting, music_drive_url: nil)
        expect(setting).to be_valid
      end

      it 'is valid with a proper https URL' do
        setting = build(:application_setting, music_drive_url: 'https://drive.google.com/drive/folders/abc123')
        expect(setting).to be_valid
      end

      it 'is invalid with a non-URL string' do
        setting = build(:application_setting, music_drive_url: 'not-a-url')
        expect(setting).not_to be_valid
        expect(setting.errors[:music_drive_url]).to include('must be a valid URL')
      end
    end

    it 'is invalid without reminder_hours_before' do
      setting = build(:application_setting, reminder_hours_before: nil)
      expect(setting).not_to be_valid
      expect(setting.errors[:reminder_hours_before]).to include("can't be blank")
    end

    it 'is invalid with zero' do
      setting = build(:application_setting, reminder_hours_before: 0)
      expect(setting).not_to be_valid
      expect(setting.errors[:reminder_hours_before]).to include('must be greater than 0')
    end

    it 'is invalid with a negative number' do
      setting = build(:application_setting, reminder_hours_before: -1)
      expect(setting).not_to be_valid
    end

    it 'is invalid with a non-integer' do
      setting = build(:application_setting, reminder_hours_before: 1.5)
      expect(setting).not_to be_valid
      expect(setting.errors[:reminder_hours_before]).to include('must be an integer')
    end
  end
end
