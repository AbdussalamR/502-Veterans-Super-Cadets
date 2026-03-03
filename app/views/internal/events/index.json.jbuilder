# frozen_string_literal: true

json.array! @events, partial: 'internal/events/event', as: :event
