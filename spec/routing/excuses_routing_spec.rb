# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::ExcusesController, type: :routing do
  describe 'routing' do
    it 'routes POST /internal/excuses/:id/cancel_recurring to internal/excuses#cancel_recurring' do
      expect(post: '/internal/excuses/1/cancel_recurring').to route_to('internal/excuses#cancel_recurring', id: '1')
    end
  end
end
