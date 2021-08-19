# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description form attributes to the DataCite types attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class CreatorContributorFunder
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite attributes containing creators, contributors, and fundingReferences keys
      def self.attributes(cocina_desc)
        new(cocina_desc).attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of DataCite attributes containing creators, contributors, and fundingReferences keys
      def attributes
        {
          creators: datacite_creators,
          contributors: datacite_contributors,
          fundingReferences: datacite_funders
        }
      end

      private

      attr_reader :cocina_desc

      def cocina_creators
        @cocina_creators ||= Array(cocina_desc.contributor).select { |cocina_contributor| datacite_creator?(cocina_contributor) }
      end

      def cocina_contributors
        @cocina_contributors ||= Array(cocina_desc.contributor).select { |cocina_contributor| !datacite_creator?(cocina_contributor) && !datacite_funder?(cocina_contributor) } +
                                 Array(cocina_desc.event).select { |cocina_event| cocina_event.type == 'publication' }.flat_map { |cocina_event| Array(cocina_event.contributor) }
      end

      def cocina_funders
        @cocina_funders ||= Array(cocina_desc.contributor).select { |cocina_contributor| datacite_funder?(cocina_contributor) }
      end

      def datacite_creator?(cocina_contributor)
        Array(cocina_contributor.note).none? { |note| note.type == 'citation status' && note.value == 'false' }
      end

      def datacite_funder?(cocina_contributor)
        marc_relator(cocina_contributor) == 'funder'
      end

      def datacite_creators
        @datacite_creators ||= cocina_creators.map { |cocina_creator| datacite_creator(cocina_creator) }
      end

      def datacite_contributors
        @datacite_contributors ||= cocina_contributors.map { |cocina_contributor| datacite_contributor(cocina_contributor) }.uniq
      end

      def datacite_funders
        @datacite_funders ||= cocina_funders.map { |cocina_funder| { funderName: cocina_funder.name.first.value } }
      end

      def datacite_creator(cocina_contributor)
        return personal_name(cocina_contributor) if person?(cocina_contributor)

        organizational_name(cocina_contributor)
      end

      def person?(cocina_contributor)
        cocina_contributor.type == 'person'
      end

      def datacite_contributor(cocina_contributor)
        datacite_creator(cocina_contributor).merge({ contributorType: contributor_type(cocina_contributor) })
      end

      def personal_name(cocina_contributor)
        forename = cocina_contributor.name.first.structuredValue.find { |part| part.type == 'forename' }
        surname = cocina_contributor.name.first.structuredValue.find { |part| part.type == 'surname' }
        {
          name: "#{surname.value}, #{forename.value}",
          givenName: forename.value,
          familyName: surname.value,
          nameType: 'Personal',
          nameIdentifiers: name_identifiers(cocina_contributor).presence
        }.compact
      end

      def organizational_name(cocina_contributor)
        {
          name: cocina_contributor.name.first.value,
          nameType: 'Organizational'
        }
      end

      def name_identifiers(cocina_contributor)
        Array(cocina_contributor.identifier).map do |identifier|
          {
            nameIdentifier: identifier.value,
            nameIdentifierScheme: identifier.type,
            schemeURI: identifier.source.uri
          }
        end
      end

      def contributor_type(cocina_contributor)
        return DATACITE_PERSON_CONTRIBUTOR_TYPES.fetch(marc_relator(cocina_contributor), 'Other') if person?(cocina_contributor)

        DATACITE_ORGANIZATION_CONTRIBUTOR_TYPES.fetch(marc_relator(cocina_contributor), 'Other')
      end

      def marc_relator(cocina_contributor)
        Array(cocina_contributor.role).find do |role|
          role&.source&.code == 'marcrelator'
        end&.value
      end

      DATACITE_PERSON_CONTRIBUTOR_TYPES = {
        'copyright holder' => 'RightsHolder',
        'compiler' => 'DataCollector',
        'editor' => 'Editor',
        'organizer' => 'Supervisor',
        'research team head' => 'ProjectLeader',
        'researcher' => 'Researcher'
      }.freeze

      DATACITE_ORGANIZATION_CONTRIBUTOR_TYPES = {
        'copyright holder' => 'RightsHolder',
        'compiler' => 'DataCollector',
        'distributor' => 'Distributor',
        'host institution' => 'HostingInstitution',
        'issuing body' => 'Distributor',
        'publisher' => 'Distributor',
        'researcher' => 'ResearchGroup',
        'sponsor' => 'Sponsor'
      }.freeze
    end
  end
end
