# frozen_string_literal: true

# Creates Event records
class EventFactory
  def self.create(druid:, event_type:, data:)
    Event.create!(druid: druid, event_type: event_type, data: data.merge(host: Socket.gethostname))
  end
end
