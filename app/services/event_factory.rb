# frozen_string_literal: true

# Creates Event records and adds the host name and invoking system identifier
class EventFactory
  def self.create(druid:, event_type:, data:)
    invoked_by = Honeybadger.get_context[:invoked_by]
    event_data = data.merge(host: Socket.gethostname, invoked_by: invoked_by)
    Event.create!(druid: druid, event_type: event_type, data: event_data)
  end
end
