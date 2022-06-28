# frozen_string_literal: true

# Create an Event
class CreateEventJob
  include Sneakers::Worker

  # This worker will connect to "dsa.create-event" queue
  # env is set to nil since by default the actual queue name would be
  # "dsa.create-event_development"
  from_queue 'dsa.create-event', env: nil

  def work(msg_str)
    Rails.logger.info("Msg_str: #{msg_str}")
    msg = JSON.parse(msg_str).with_indifferent_access
    Rails.logger.info("Msg: #{msg}")
    Rails.logger.info("Event_type: #{msg[:event_type]}")
    Event.create!(druid: msg[:druid], event_type: msg[:event_type], data: msg[:data])
    ack!
  end
end
