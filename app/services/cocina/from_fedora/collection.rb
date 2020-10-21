# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Collection objects from Fedora objects
    class Collection
      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      def props
        {
          externalIdentifier: item.pid,
          type: Cocina::Models::Vocab.collection,
          label: item.label,
          version: item.current_version.to_i,
          administrative: FromFedora::Administrative.props(item),
          access: Access.collection_props(item)
        }.tap do |props|
          description = FromFedora::Descriptive.props(item)
          props[:description] = description unless description.nil?
          identification = FromFedora::Identification.props(item)
          identification[:catalogLinks] = [{ catalog: 'symphony', catalogRecordId: item.catkey }] if item.catkey
          props[:identification] = identification unless identification.empty?
        end
      end

      private

      attr_reader :item
    end
  end
end
