# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina::Identification object properties from Fedora objects
    class Identification
      # @param [Dor::Item,Dor::Collection,Dor::Etd] fedora_object
      # @return [Hash] a hash that can be mapped to a Cocina::Identification object
      # @raises [Mapper::MissingSourceID]
      def self.props(fedora_object)
        new(fedora_object).props
      end

      def initialize(fedora_object)
        @fedora_object = fedora_object
      end

      def props
        {
          barcode: fedora_object.identityMetadata.barcode,
          doi: doi,
          sourceId: source_id,
          catalogLinks: catalog_links
        }.compact
      end

      private

      attr_reader :fedora_object

      def source_id
        if fedora_object.source_id
          fedora_object.source_id.strip.sub(/ *: */, ':')
        elsif fedora_object.is_a? Dor::Collection
          nil
        else
          # ETDs post Summer 2020 have a source id, but legacy ones don't.  In that case look for a dissertation_id.
          dissertation = fedora_object.otherId.find { |id| id.start_with?('dissertationid:') }
          raise Mapper::MissingSourceID, "unable to resolve a sourceId for #{fedora_object.pid}" unless dissertation

          dissertation
        end
      end

      def doi
        # We began to record DOI names in identityMetadata in the Summer of 2021
        value = fedora_object.identityMetadata.ng_xml.xpath('//doi').first
        return value.text if value

        # Prior to that we only had DOI links in the descMetadata
        value = fedora_object.descMetadata.ng_xml.xpath('//identifier[@type="doi"]').first
        return unless value

        value.text.delete_prefix('https://doi.org/')
      end

      def catalog_links
        fedora_object.identityMetadata.ng_xml.xpath('//otherId[@name="catkey"]').map do |id|
          {
            catalog: 'symphony',
            catalogRecordId: id.text
          }
        end
      end
    end
  end
end
