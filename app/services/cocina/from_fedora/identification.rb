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
        return { sourceId: item.source_id } if item.source_id

        return {} if item.is_a? Dor::Collection

        # ETDs post Summer 2020 have a source id, but legacy ones don't.  In that case look for a dissertation_id.
        dissertation = item.otherId.find { |id| id.start_with?('dissertationid:') }
        raise Mapper::MissingSourceID, "unable to resolve a sourceId for #{item.pid}" unless dissertation

        { sourceId: dissertation }
      end

      private

      attr_reader :item
    end
  end
end
