# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExcusesController, type: :routing do
  describe 'routing' do
    it 'routes POST /excuses/:id/cancel_recurring to excuses#cancel_recurring' do
      expect(post: '/excuses/1/cancel_recurring').to route_to('excuses#cancel_recurring', id: '1')
    end
  end
end
