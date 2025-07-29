# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DRO schema to DataCite attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Attributes
      # @param [Cocina::Models::DRO] cocina_item
      # @param [String] url URL to be used for the item. If not provided, will use the PURL for the item.
      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.mapped_from_cocina(cocina_item, url: nil)
        return unless cocina_item&.dro?

        new(cocina_item, url:).mapped_from_cocina
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

      def initialize(cocina_item, url: nil)
        @access = cocina_item.access
        @description = cocina_item.description
        @purl = Purl.for(druid: cocina_item.externalIdentifier)
        @url = url || @purl
      end

      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def mapped_from_cocina
        {
          event: 'publish', # Makes a findable DOI
          url:,
          descriptions:,
          alternateIdentifiers: alternate_identifiers,
          dates: [], # to be implemented from event_h2 mapping
          identifiers:,
          subjects:,
          titles:,
          rightsList: rights_list,
          types: types_attributes,
          publicationYear: publication_year,
          publisher: 'Stanford Digital Repository',
          relatedItems: related_items,
          relatedIdentifiers: related_identifiers
        }.merge(creator_contributor_funder_attributes).compact
      end

      private

      attr_reader :access, :description, :purl, :url

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

      def related_items
        Array(description&.relatedResource).filter_map do |related_resource|
          RelatedResource.related_item_attributes(related_resource)
        end
      end

      def related_identifiers
        Array(description&.relatedResource).filter_map do |related_resource|
          RelatedResource.related_identifier_attributes(related_resource)
        end
      end

      def rights_list
        DroAccess.rights_list_attributes(access)
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
