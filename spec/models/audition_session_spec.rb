require 'rails_helper'

RSpec.describe AuditionSession, type: :model do
  describe "valid audition session" do
    it "is valid with all required fields" do
      session = build(:audition_session)
      expect(session).to be_valid
    end
  end

  describe "validations" do
    it "is invalid without a label" do
      session = build(:audition_session, label: nil)
      expect(session).not_to be_valid
    end

    it "is invalid without a location" do
      session = build(:audition_session, location: nil)
      expect(session).not_to be_valid
    end

    it "is invalid without a start_datetime" do
      session = build(:audition_session, start_datetime: nil)
      expect(session).not_to be_valid
    end

    it "is invalid without an end_datetime" do
      session = build(:audition_session, end_datetime: nil)
      expect(session).not_to be_valid
    end

    it "is invalid when end_datetime is before start_datetime" do
      session = build(:audition_session, start_datetime: 1.week.from_now, end_datetime: 1.day.from_now)
      expect(session).not_to be_valid
      expect(session.errors[:end_datetime]).to include("must be after start")
    end

    it "is invalid when end_datetime equals start_datetime" do
      time = 1.week.from_now
      session = build(:audition_session, start_datetime: time, end_datetime: time)
      expect(session).not_to be_valid
    end
  end
end