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

      def initialize(cocina_item)
        @cocina_item = cocina_item
      end

      # @return [Hash] Hash of DataCite attributes, conforming to the expectations of HTTP PUT request to DataCite
      def mapped_from_cocina
        {}.tap do |attribs|
          attribs[:alternateIdentifiers] = [alternate_identifier] if alternate_identifier
          attribs[:creators] = [{ name: 'TBD' }] # to be implemented from contributors_h2 mapping
          attribs[:dates] = [] # to be implemented from event_h2 mapping
          attribs[:descriptions] = [description] if description
          attribs[:identifiers] = [identifier] if identifier
          attribs[:publicationYear] = '1964' # to be implemented from event_h2 mapping,
          attribs[:publisher] = 'to be implemented' # to be implemented from event_h2 mapping
          # NOTE: Per email from DataCite support on 7/21/2021, relatedItem is not currently supported in the ReST API v2.
          # Support will be added for the entire DataCite MetadataKernel 4.4 schema in v3 of the ReST API.
          # attribs[:relatedItems] = [related_item] if related_item
          attribs[:rightsList] = [rights] if rights
          attribs[:subjects] = [] # to be implemented from subject_h2 mapping
          attribs[:titles] = [title] if title
          attribs[:types] = types_attributes if types_attributes
        end
      end

      private

      attr :cocina_item

      def alternate_identifier
        @alternate_identifier ||= Identifier.alternate_identifier_attributes(cocina_item.description)
        @alternate_identifier.presence
      end

      def description
        @description ||= Note.descriptions_attributes(cocina_item.description)
        @description.presence
      end

      def identifier
        @identifier ||= Identifier.identifier_attributes(cocina_item.description)
        @identifier.presence
      end

      # NOTE: Per email from DataCite support on 7/21/2021, relatedItem is not currently supported in the ReST API v2.
      # Support will be added for the entire DataCite MetadataKernel 4.4 schema in v3 of the ReST API.
      # def related_item
      #   @related_item ||= RelatedResource.related_item_attributes(cocina_item.description)
      #   @related_item.presence
      # end

      def rights
        @rights ||= DROAccess.rights_list_attributes(cocina_item.access)
        @rights.presence
      end

      def title
        @title ||= Title.title_attributes(cocina_item.description)
        @title.presence
      end

      def types_attributes
        @types_attributes ||= Form.type_attributes(cocina_item.description)
        @types_attributes.presence
      end
    end
  end
end
