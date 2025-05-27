# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description relatedResource attributes to the DataCite relatedItem attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class RelatedResource
      # @param [Cocina::Models::RelatedResource] related_resource
      # @return [Hash] Hash of DataCite relatedItem attributes, conforming to the expectations of HTTP PUT
      # request to DataCite or nil if blank
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def self.related_item_attributes(related_resource)
        new(related_resource).related_item_attributes
      end

      def initialize(related_resource)
        @related_resource = related_resource
      end

      # @return [Hash,nil] Array of DataCite relatedItem attributes, conforming to the expectations of HTTP PUT
      # request to DataCite or nil if blank
      #  see https://support.datacite.org/reference/dois-2#put_dois-id
      def related_item_attributes
        return if related_resource_blank?

        {
          relatedItemType: 'Other',
          relationType: 'References'
        }.tap do |attribs|
          attribs[:titles] = [title: related_item_title] if related_item_title
          if related_item_identifier_url
            attribs[:relatedItemIdentifier] = related_item_identifier_url
            attribs[:relatedItemIdentifierType] = 'URL'
          end
        end
      end

      private

      attr_reader :related_resource

      def related_resource_blank?
        return true if related_resource.blank?

        related_resource_hash = related_resource.to_h
        related_resource_hash.blank? || related_resource_hash.each_value.all?(&:blank?)
      end

      def related_item_title
        @related_item_title ||= preferred_citation || other_title
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
        Array(related_resource.note).find do |note|
          note.type == 'preferred citation' && note.value.present?
        end&.value
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
        Array(related_resource.title).find do |title|
          title.value.present?
        end&.value
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
        @related_item_identifier_url ||= Array(related_resource.access&.url).find do |url|
          url.value.present?
        end&.value
      end
    end
  end
end
