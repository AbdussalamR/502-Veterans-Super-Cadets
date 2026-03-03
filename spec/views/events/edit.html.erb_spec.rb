# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'internal/events/edit', type: :view do
  let(:event) do
    Event.create!(
      title: 'MyString',
      date: Time.zone.today,
      end_time: Time.zone.today + 2.hours,
      location: 'MyString',
      description: 'MyText'
    )
  end

  before(:each) do
    assign(:event, event)
  end

  it 'renders the edit event form' do
    render

    assert_select 'form[action=?][method=?]', internal_event_path(event), 'post' do
      assert_select 'input[name=?]', 'event[title]'

      assert_select 'input[name=?]', 'event[date]'

      assert_select 'input[name=?]', 'event[location]'

      assert_select 'textarea[name=?]', 'event[description]'
    end
  end
end
