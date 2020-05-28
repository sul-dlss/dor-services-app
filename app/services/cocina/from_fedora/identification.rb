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
        case item
        when Dor::Etd
          # ETDs don't have source_id, but we can use the dissertationid (in otherId) for this purpose
          { sourceId: item.otherId.find { |id| id.start_with?('dissertationid:') } }
        when Dor::Collection
          {}
        else
          { sourceId: item.source_id }
        end
      end

      private

      attr_reader :item
    end
  end
end
