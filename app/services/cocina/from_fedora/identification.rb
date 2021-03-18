# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Identification objects from Fedora objects
    class Identification
      # @param [Dor::Item,Dor::Collection,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      # @raises [Mapper::MissingSourceID]
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        {
          sourceId: source_id,
          barcode: item.identityMetadata.barcode
        }.compact
      end

      private

      attr_reader :item

      def source_id
        if item.source_id
          item.source_id
        elsif item.is_a? Dor::Collection
          nil
        else
          # ETDs post Summer 2020 have a source id, but legacy ones don't.  In that case look for a dissertation_id.
          dissertation = item.otherId.find { |id| id.start_with?('dissertationid:') }
          raise Mapper::MissingSourceID, "unable to resolve a sourceId for #{item.pid}" unless dissertation

          dissertation
        end
      end
    end
  end
end
