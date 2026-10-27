# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes when and by whom the object was last registered, opened, updated, or closed
    class EventsIndexer
      # @param [Event, nil] last_event the most recent update event (see Event.last_updates_for)
      def initialize(last_event:, **)
        @last_event = last_event
      end

      # @return [Hash] the partial solr document for event concerns
      def to_solr
        return {} unless last_event

        {
          'last_updated_at_dtpsidv' => last_event.created_at&.utc&.iso8601,
          'last_updated_by_ssidv' => last_event.who.presence
        }.compact
      end

      private

      attr_reader :last_event
    end
  end
end
