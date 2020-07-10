# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Identification objects from Fedora objects
    class Identification
      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        return {} if item.is_a? Dor::Collection

        return { sourceId: item.source_id } if item.source_id

        # ETDs post Summer 2020 have a source id, but legacy ones don't.  In that case look for a dissertation_id.
        dissertation = item.otherId.find { |id| id.start_with?('dissertationid:') }
        raise "unable to resolve a sourceId for #{item.pid}" unless dissertation

        { sourceId: dissertation }
      end

      private

      attr_reader :item
    end
  end
end
