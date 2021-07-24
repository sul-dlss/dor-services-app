# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DRO.description.event attributes to appropriate DataCite attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Event
      def initialize(cocina_item)
        @cocina_item = cocina_item
      end

      # For DataCite publicationYear, use year embargo lifted if present,
      #  otherwise use deposit year, regardless of publication date entered
      #
      # @return [String] publication year, conforming to the expectations of HTTP PUT request to DataCite
      def pub_year
        if embargo?
          embargo_release_date = cocina_dro_access&.embargo&.releaseDate
          embargo_release_date&.year&.to_s
        elsif deposit_event_publication_date
          DateTime.parse(deposit_event_publication_date).year&.to_s
        end
      end

      # Add Stanford Digital Repository as publisher to cocina release event if present, otherwise deposit event
      def publisher
        # TODO: implement this
      end

      # For DataCite dates
      # H2 publication date > cocina event/date type publication > DataCite date type Issued
      # H2 deposit date > cocina event type deposit > DataCite date type Submitted
      ## If no embargo, > cocina date type publication
      ## If embargo, > cocina date type deposit
      # H2 embargo end date > cocina event type release and date type publication > DataCite date type Available
      def dates
        # TODO: implement this
      end

      private

      attr :cocina_item

      def embargo?
        cocina_dro_access&.embargo&.releaseDate.presence
      end

      def deposit_event_publication_date
        deposit_event&.date&.find { |date| date&.type == 'publication' }&.value
      end

      def deposit_event
        cocina_events&.find { |event| event&.type == 'deposit' }
      end

      def cocina_events
        @cocina_events ||= cocina_item.description.event
      end

      # embargo is in Cocina::Models::DROAccess -- the top level access, not description.access
      def cocina_dro_access
        @cocina_dro_access ||= cocina_item.access
      end
    end
  end
end
