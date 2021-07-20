# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description relatedResource attributes to the DataCite relatedItem attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    # relatedItem attribute new in DataCite schema v. 4.4 and not included in API docs as of 2021-07
    #  see https://schema.datacite.org/meta/kernel-4.4/
    class RelatedResource
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite relatedItem attributes, conforming to the expectations of HTTP PUT request to DataCite
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def self.related_item_attributes(cocina_desc)
        new(cocina_desc).related_item_attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of DataCite relatedItem attributes, conforming to the expectations of HTTP PUT request to DataCite
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def related_item_attributes
        return {} if cocina_desc&.relatedResource.nil?

        {
          relatedItemType: 'Other',
          relationType: 'References'
        }.tap do |attribs|
          attribs[:Title] = [title: related_item_title] if related_item_title
          attribs[:relatedItemIdentifier] = [related_item_identifier] if related_item_identifier
        end
      end

      private

      attr :cocina_desc

      def related_item_title
        @related_item_title ||= preferred_citation || other_title
      end

      def related_item_identifier
        @related_item_identifier ||=
          if related_item_identifier_url
            {
              relatedItemIdentifier: related_item_identifier_url,
              relatedItemIdentifierType: 'URL'
            }
          end
      end

      # example cocina relatedResource:
      #   {
      #     note: [
      #       {
      #         value: 'Stanford University (Stanford, CA.). (2020). yadda yadda',
      #         type: 'preferred citation'
      #       }
      #     ]
      #   }
      def preferred_citation
        cocina_desc.relatedResource&.each do |related_resource|
          related_resource.note&.each do |note|
            return note.value if note.type == 'preferred citation' && note.value.present?
          end
        end
        nil
      end

      # example cocina relatedResource:
      #   {
      #     title: [
      #       {
      #         value: 'A paper'
      #       }
      #     ]
      #   }
      def other_title
        cocina_desc.relatedResource&.each do |related_resource|
          related_resource.title&.each do |title|
            return title.value if title.value.present?
          end
        end
        nil
      end

      # example cocina relatedResource:
      #   {
      #     access: {
      #       url: [
      #         {
      #           value: 'https://www.example.com/paper.html'
      #         }
      #       ]
      #     }
      #   }
      def related_item_identifier_url
        cocina_desc.relatedResource&.each do |related_resource|
          related_resource.access&.url&.each do |url|
            return url.value if url.value.present?
          end
        end
        nil
      end
    end
  end
end
