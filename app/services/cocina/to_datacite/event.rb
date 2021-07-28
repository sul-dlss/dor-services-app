# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DRO.description.event attributes to appropriate DataCite attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Event
      def initialize(cocina_item)
        @cocina_item = cocina_item
      end

      # DataCite publicationYear is the year (YYYY) the object is published to purl, and is either:
      ## The embargo end date, if present (cocina event type release, date type publication)
      ## The deposit date (cocina event type deposit, date type publication)
      #
      # @return [String] publication year, conforming to the expectations of HTTP PUT request to DataCite
      def pub_year
        if embargo?
          embargo_release_date = cocina_dro_access&.embargo&.releaseDate
          embargo_release_date&.year&.to_s
        elsif deposit_event_publication_date_value
          DateTime.parse(deposit_event_publication_date_value).year&.to_s
        end
      end

      # H2 publisher role > same cocina event as publication date > see DataCite contributor mappings
      # Add Stanford Digital Repository as publisher to cocina release event if present, otherwise deposit event
      #
      # sdr is the publisher for the event where the content becomes public via purl -- deposit if no embargo, release if embargo present.
      # if it's not public via purl, sdr should not be the publisher;
      #   the user may enter someone with the publisher role in h2, referring to publication in another venue, regardless of the purl status.
      def publisher
        # TODO: implement this
      end

      # DataCite date (YYYY-MM-DD) is repeatable and each DataCite data has an associated type attribute
      # @return [Array<Hash>] DataCite date hashs, conforming to the expectations of HTTP PUT request to DataCite
      def dates
        [].tap do |dates|
          dates << submitted_date if submitted_date.present?
          dates << available_date if available_date.present?
          dates << issued_date if issued_date.present?
          dates << created_date if created_date.present?
        end
      end

      private

      attr :cocina_item

      def embargo?
        cocina_dro_access&.embargo&.releaseDate.presence
      end

      # If embargo,
      #   Cocina event type deposit, date type deposit maps to DataCite date type Submitted
      # If no embargo
      #   Cocina event type deposit, date type publication maps to DataCite date type Submitted
      # If no embargo and no deposit event with date type publication,
      #   Cocina event type publication, date type publication maps to DataCite date type Submitted
      def submitted_date
        @submitted_date ||= {}.tap do |submitted_date|
          if embargo? && deposit_event_deposit_date_value.present?
            submitted_date[:date] = deposit_event_deposit_date_value
          elsif deposit_event_publication_date_value.present? # no embargo
            submitted_date[:date] = deposit_event_publication_date_value
          elsif publication_event_publication_date_value.present? # no embargo
            submitted_date[:date] = publication_event_publication_date_value
          end
          submitted_date[:dateType] = 'Submitted' if submitted_date.present?
        end
      end

      # from Arcadia:
      #   Cocina event type release, date type publication maps to DataCite date type Available
      # In actuality:
      #   embargo release date is in DROAccess, not in an event
      def available_date
        return unless embargo?

        @available_date ||=
          {
            date: cocina_dro_access&.embargo&.releaseDate,
            dateType: 'Available'
          }
      end

      # Cocina event type publication, date type publication maps to DataCite date type Issued
      def issued_date
        return if publication_event_publication_date_value.blank?

        @issued_date ||=
          {
            date: publication_event_publication_date_value,
            dateType: 'Issued'
          }
      end

      # Cocina event type creation, date type creation maps to DataCite date type Created
      def created_date
        return if creation_event_creation_date.blank?

        @created_date ||= begin
          created_date = {
            dateType: 'Created'
          }
          if creation_event_creation_date.value
            created_date[:date] = creation_event_creation_date.value
            created_date[:dateInformation] = creation_event_creation_date.qualifier if creation_event_creation_date.qualifier.present?
          else
            created_date.merge!(structured_date_result(creation_event_creation_date))
          end

          created_date
        end
      end

      def deposit_event_deposit_date_value
        @deposit_event_deposit_date_value ||= deposit_event&.date&.find { |date| date&.type == 'deposit' }&.value
      end

      def deposit_event_publication_date_value
        @deposit_event_publication_date_value ||= deposit_event&.date&.find { |date| date&.type == 'publication' }&.value
      end

      def deposit_event
        @deposit_event ||= cocina_events&.find { |event| event&.type == 'deposit' }
      end

      def publication_event_publication_date_value
        @publication_event_publication_date_value ||= publication_event&.date&.find { |date| date&.type == 'publication' }&.value
      end

      def publication_event
        @publication_event ||= cocina_events&.find { |event| event&.type == 'publication' }
      end

      def creation_event_creation_date
        @creation_event_creation_date ||= creation_event&.date&.find { |date| date&.type == 'creation' }
      end

      def creation_event
        @creation_event ||= cocina_events&.find { |event| event&.type == 'creation' }
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def structured_date_result(date)
        return unless date.structuredValue

        start_date, end_date, = ''
        info = date.qualifier if date.qualifier.present?
        date.structuredValue.each do |structured_val|
          start_date = structured_val.value if structured_val.type == 'start'
          end_date = structured_val.value if structured_val.type == 'end'
          info = structured_val.qualifier if structured_val.qualifier
        end

        result_date = if start_date.present? && end_date.present?
                        "#{start_date}/#{end_date}"
                      elsif start_date.present?
                        start_date
                      elsif end_date.present?
                        end_date
                      end

        {
          date: result_date
        }.tap do |attributes|
          attributes[:dateInformation] = info if info.present? && result_date.present?
        end.compact
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

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
