# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'events/new', type: :view do
  before(:each) do
    assign(:event, Event.new(
                     title: 'MyString',
                     date: Time.zone.today,
                     location: 'MyString',
                     description: 'MyText'
                   ))
  end

  it 'renders new event form' do
    render

    assert_select 'form[action=?][method=?]', events_path, 'post' do
      assert_select 'input[name=?]', 'event[title]'

      assert_select 'input[name=?]', 'event[date]'

      assert_select 'input[name=?]', 'event[location]'

      assert_select 'textarea[name=?]', 'event[description]'
    end
  end
end
