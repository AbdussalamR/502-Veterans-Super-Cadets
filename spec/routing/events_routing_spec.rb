# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Internal::EventsController, type: :routing do
  describe 'routing' do
    it 'routes to #index' do
      expect(get: '/internal/events').to route_to('internal/events#index')
    end

    it 'routes to #new' do
      expect(get: '/internal/events/new').to route_to('internal/events#new')
    end

    it 'routes to #show' do
      expect(get: '/internal/events/1').to route_to('internal/events#show', id: '1')
    end

    it 'routes to #edit' do
      expect(get: '/internal/events/1/edit').to route_to('internal/events#edit', id: '1')
    end

    it 'routes to #create' do
      expect(post: '/internal/events').to route_to('internal/events#create')
    end

    it 'routes to #update via PUT' do
      expect(put: '/internal/events/1').to route_to('internal/events#update', id: '1')
    end

    it 'routes to #update via PATCH' do
      expect(patch: '/internal/events/1').to route_to('internal/events#update', id: '1')
    end

    it 'routes to #destroy' do
      expect(delete: '/internal/events/1').to route_to('internal/events#destroy', id: '1')
    end

    it 'routes self check-in form' do
      expect(get: '/internal/events/1/self_checkin').to route_to('internal/attendances#self_checkin_form', id: '1')
    end

    it 'routes self check-in submission' do
      expect(post: '/internal/events/1/self_checkin').to route_to('internal/attendances#self_checkin', id: '1')
    end
  end
end
