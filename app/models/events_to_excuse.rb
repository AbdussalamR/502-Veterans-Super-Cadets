class EventsToExcuse < ApplicationRecord
  self.table_name = "events_to_excuse"

  belongs_to :event, inverse_of: :events_to_excuses
  belongs_to :excuse, inverse_of: :events_to_excuses, optional: true
end