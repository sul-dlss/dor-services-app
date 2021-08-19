# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DRO schema to DataCite attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Attributes
      # @param [Cocina::Models::DRO] cocina_item
      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.mapped_from_cocina(cocina_item)
        return unless cocina_item&.dro?

        new(cocina_item).mapped_from_cocina
      end

      # @param [Cocina::Models::DRO] cocina_item
      # To be exportable an item must have a creator, and resourceTypeGeneral.
      # @return [Boolean] is this item exportable to datacite
      def self.exportable?(cocina_item)
        new(cocina_item).exportable?
      end

      def exportable?
        types_attributes&.fetch(:resourceTypeGeneral).present? && creators.present?
      end

      def initialize(cocina_item)
        @access = cocina_item.access
        @description = cocina_item.description
      end

      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def mapped_from_cocina
        {
          event: 'publish', # Makes a findable DOI
          descriptions: descriptions,
          alternateIdentifiers: alternate_identifiers,
          dates: [], # to be implemented from event_h2 mapping
          identifiers: identifiers,
          subjects: subjects,
          titles: titles,
          rightsList: rights_list,
          types: types_attributes,
          publicationYear: publication_year,
          publisher: 'Stanford Digital Repository'
          # NOTE: Per email from DataCite support on 7/21/2021, relatedItem is not currently supported in the ReST API v2.
          # Support will be added for the entire DataCite MetadataKernel 4.4 schema in v3 of the ReST API.
          # relatedItems: related_item
        }.merge(creator_contributor_funder_attributes).compact
      end

      private

      attr :access, :description

      def publication_year
        date = if access.embargo
                 access.embargo.releaseDate.to_datetime
               else
                 Time.zone.today
               end
        date.year.to_s
      end

      def creator_contributor_funder_attributes
        CreatorContributorFunder.attributes(description)
      end

      def creators
        creator_contributor_funder_attributes[:creators]
      end

      def alternate_identifiers
        Identifier.alternate_identifier_attributes(description)
      end

      def descriptions
        Note.descriptions_attributes(description)
      end

      def identifiers
        Identifier.identifier_attributes(description)
      end

      # NOTE: Per email from DataCite support on 7/21/2021, relatedItem is not currently supported in the ReST API v2.
      # Support will be added for the entire DataCite MetadataKernel 4.4 schema in v3 of the ReST API.
      # def related_items
      #   RelatedResource.related_item_attributes(cocina_item.description)
      # end

      def rights_list
        DROAccess.rights_list_attributes(access)
      end

      def subjects
        Subject.subjects_attributes(description)
      end

      def titles
        Title.title_attributes(description)
      end

      def types_attributes
        Form.type_attributes(description)
      end
    end
  end
end
