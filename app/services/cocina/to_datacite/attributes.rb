# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DRO schema to DataCite attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Attributes
      # @param [Cocina::Models::DRO] cocina_dro
      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.mapped_from_cocina(cocina_dro)
        return unless cocina_dro&.dro?

        new(cocina_dro).mapped_from_cocina
      end

      def initialize(cocina_dro)
        @cocina_dro = cocina_dro
      end

      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def mapped_from_cocina
        return if !cocina_dro&.dro? || doi.nil?

        {
          doi: doi,
          prefix: doi_prefix
        }.tap do |attribs|
          attribs[:alternateIdentifiers] = [alternate_identifier] if alternate_identifier
          attribs[:creators] = [] # to be implemented from contributors_h2 mapping
          attribs[:dates] = [] # to be implemented from event_h2 mapping
          attribs[:descriptions] = [description] if description
          attribs[:identifiers] = [identifier] if identifier
          attribs[:publicationYear] = 1964 # to be implemented from event_h2 mapping,
          attribs[:publisher] = 'to be implemented' # to be implemented from event_h2 mapping
          attribs[:relatedItems] = [related_item] if related_item
          attribs[:subjects] = [] # to be implemented from subject_h2 mapping
          attribs[:titles] = [title] if title
          attribs[:types] = types_attributes if types_attributes
        end
      end

      private

      attr :cocina_dro

      #  example: '10.25740/bc123df4567'
      # @return [String] DOI of object or nil
      def doi
        cocina_dro.identification.doi
      end

      # @return [String] DOI prefix, e.g. '10.25740' for '10.25740/bc123df4567'
      def doi_prefix
        return unless doi

        doi.split('/').first
      end

      def alternate_identifier
        @alternate_identifier ||= Identifier.alternate_identifier_attributes(cocina_dro.description)
        @alternate_identifier.presence
      end

      def description
        @description ||= Note.descriptions_attributes(cocina_dro.description)
        @description.presence
      end

      def identifier
        @identifier ||= Identifier.identifier_attributes(cocina_dro.description)
        @identifier.presence
      end

      def related_item
        @related_item ||= RelatedResource.related_item_attributes(cocina_dro.description)
        @related_item.presence
      end

      def title
        @title ||= Title.title_attributes(cocina_dro.description)
        @title.presence
      end

      def types_attributes
        @types_attributes ||= Form.type_attributes(cocina_dro.description)
        @types_attributes.presence
      end
    end
  end
end
