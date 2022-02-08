# frozen_string_literal: true

# Service for migrating events from the events datastream to the DB.
class EventsMigrationService
  def self.migrate(fedora_object)
    new(fedora_object).migrate
  end

  def initialize(fedora_object)
    @fedora_object = fedora_object
  end

  def migrate
    return unless fedora_object.events

    fedora_object.events.each_event do |event_type, who, timestamp, message|
      migrate_event(event_type, who, timestamp, message)
    end
  end

  private

  attr_reader :fedora_object

  def migrate_event(event_type, who, timestamp, message)
    version = version_from_message(message)
    create_event('version_open', who, timestamp, version) if event_type == 'open' && version && existing_open_versions.exclude?(version)

    create_event('version_close', who, timestamp, version) if event_type == 'close' && version && existing_close_versions.exclude?(version)
  end

  def version_from_message(message)
    match = message.match(/Version (\d+)/)
    return nil unless match

    match[1]
  end

  def create_event(event_type, who, timestamp, version)
    data = { who: who.presence, version: version }.compact
    Event.create!(druid: fedora_object.pid, event_type: event_type, created_at: timestamp, data: data)
  end

  def existing_open_versions
    @existing_open_versions = Event.where(druid: fedora_object.pid, event_type: 'version_open').map { |event| event.data['version'] }
  end

  def existing_close_versions
    @existing_close_versions = Event.where(druid: fedora_object.pid, event_type: 'version_close').map { |event| event.data['version'] }
  end
end
