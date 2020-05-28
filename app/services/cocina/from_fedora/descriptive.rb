# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina administrative model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        desc = { title: [{ status: 'primary', value: TitleMapper.build(item) }] }

        # collections are registered with abstracts
        return desc if item.descMetadata.abstract.blank?

        desc[:note] = [{ type: 'summary', value: item.descMetadata.abstract.first }]
        desc
      end

      private

      attr_reader :item
    end
  end
end
