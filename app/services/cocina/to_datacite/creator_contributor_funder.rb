# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description form attributes to the DataCite types attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class CreatorContributorFunder
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
        @cocina_creators ||= Array(cocina_desc.contributor).select do |cocina_contributor|
          datacite_creator?(cocina_contributor)
        end
      end

      def cocina_contributors
        @cocina_contributors ||= Array(cocina_desc.contributor).select do |cocina_contributor|
          datacite_publisher?(cocina_contributor)
        end
      end

      def cocina_funders
        @cocina_funders ||= Array(cocina_desc.contributor).select do |cocina_contributor|
          datacite_funder?(cocina_contributor)
        end
      end

      def datacite_creator?(cocina_contributor)
        !datacite_funder?(cocina_contributor) && !datacite_publisher?(cocina_contributor)
      end

      def datacite_funder?(cocina_contributor)
        marc_relator(cocina_contributor) == 'funder'
      end

      def datacite_publisher?(cocina_contributor)
        marc_relator(cocina_contributor) == 'publisher'
      end

      def datacite_creators
        @datacite_creators ||= cocina_creators.map { |cocina_creator| datacite_creator(cocina_creator) }.uniq
      end

      def datacite_contributors
        @datacite_contributors ||= cocina_contributors.map do |cocina_contributor|
          datacite_contributor(cocina_contributor)
        end.uniq
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

      def personal_name(cocina_contributor) # rubocop:disable Metrics/AbcSize
        {
          nameType: 'Personal',
          nameIdentifiers: name_identifiers(cocina_contributor).presence,
          affiliation: affiliations(cocina_contributor).presence
        }.tap do |name_hash|
          # NOTE: This is needed for ETDs, for which we do not receive structured
          #       contributor names from Axess for ETD readers
          if cocina_contributor.name.first.structuredValue.empty?
            name_hash[:creatorName] = name_hash[:name] = cocina_contributor.name.first.value
          else
            forename = cocina_contributor.name.first.structuredValue.find { |part| part.type == 'forename' }
            surname = cocina_contributor.name.first.structuredValue.find { |part| part.type == 'surname' }

            name_hash[:name] = "#{surname.value}, #{forename.value}"
            name_hash[:givenName] = forename.value
            name_hash[:familyName] = surname.value
          end
        end
          .compact
      end

      def organizational_name(cocina_contributor)
        name = cocina_contributor.name.first.structuredValue.first || cocina_contributor.name.first
        {
          name: name.value,
          nameType: 'Organizational',
          nameIdentifiers: name_identifiers(name).presence
        }.compact
      end

      def name_identifiers(cocina_contributor)
        Array(cocina_contributor.identifier).map do |identifier|
          {
            nameIdentifier: identifier.value || identifier.uri,
            nameIdentifierScheme: identifier.type,
            schemeURI: identifier.source.uri
          }.compact
        end
      end

      def affiliations(cocina_contributor)
        Array(cocina_contributor.affiliation).map do |affiliation|
          institution = affiliation.structuredValue.find { |descriptive_value| descriptive_value.identifier.present? }
          institution ||= affiliation # if no structured value with identifier, use the affiliation itself
          identifier = institution.identifier.find { |id| id.type == 'ROR' }
          next unless identifier&.uri

          {
            affiliationIdentifier: identifier.uri,
            affiliationIdentifierScheme: 'ROR',
            name: institution.value,
            schemeUri: 'https://ror.org/'
          }.compact
        end
      end

      def contributor_type(cocina_contributor)
        if person?(cocina_contributor)
          return DATACITE_PERSON_CONTRIBUTOR_TYPES.fetch(marc_relator(cocina_contributor),
                                                         'Other')
        end

        DATACITE_ORGANIZATION_CONTRIBUTOR_TYPES.fetch(marc_relator(cocina_contributor), 'Other')
      end

      def marc_relator(cocina_contributor)
        Array(cocina_contributor.role).find do |role|
          role&.source&.code == 'marcrelator'
        end&.value
      end
    end
  end
end
