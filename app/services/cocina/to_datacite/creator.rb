# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description form attributes to the DataCite types attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Creator
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite types attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.attributes(cocina_desc)
        new(cocina_desc).attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      attr_reader :cocina_desc

      # @return [Hash] Hash of DataCite types attributes, conforming to the expectations of HTTP PUT request to DataCite
      def attributes
        creators = Array(cocina_desc.contributor).reject do |contributor|
          Array(contributor.note).any? { |note| note.type == 'citation status' && note.value == 'false' }
        end

        creators.map do |creator|
          case creator.type
          when 'person'
            personal_name(creator)
          else
            organizational_name(creator)
          end
        end
      end

      def personal_name(creator)
        forename = creator.name.first.structuredValue.find { |part| part.type == 'forename' }
        surname = creator.name.first.structuredValue.find { |part| part.type == 'surname' }
        {
          name: "#{surname.value}, #{forename.value}",
          givenName: forename.value,
          familyName: surname.value,
          nameType: 'Personal',
          nameIdentifiers: name_identifiers(creator).presence
        }.compact
      end

      def organizational_name(creator)
        {
          name: creator.name.first.value,
          nameType: 'Organizational'
        }
      end

      def name_identifiers(creator)
        Array(creator.identifier).map do |identifier|
          {
            nameIdentifier: identifier.value,
            nameIdentifierScheme: identifier.type,
            schemeURI: identifier.source.uri
          }
        end
      end
    end
  end
end
