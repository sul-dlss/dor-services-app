# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Collection objects from Fedora objects
    class Collection
      # @param [Dor::Item,Dor::Etd] item
      # @param [Cocina::FromFedora::DataErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.props(item, notifier: nil)
        new(item, notifier: notifier).props
      end

      def initialize(item, notifier: nil)
        @item = item
        @notifier = notifier
      end

      def props
        {
          externalIdentifier: item.pid,
          type: Cocina::Models::Vocab.collection,
          label: item.label,
          version: item.current_version.to_i,
          administrative: FromFedora::Administrative.props(item),
          access: Access.collection_props(item.rightsMetadata)
        }.tap do |props|
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: item.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder, mods: item.descMetadata.ng_xml, druid: item.pid, notifier: notifier)
          props[:description] = description unless description.nil?
          identification = FromFedora::Identification.props(item)
          identification[:catalogLinks] = [{ catalog: 'symphony', catalogRecordId: item.catkey }] if item.catkey
          props[:identification] = identification unless identification.empty?
        end
      end

      private

      attr_reader :item, :notifier
    end
  end
end
