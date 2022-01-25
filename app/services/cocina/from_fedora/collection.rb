# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina::Collection object properties from Fedora objects
    class Collection
      # @param [Dor::Collection] fedora_collection
      # @param [Cocina::FromFedora::DataErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a Cocina::Collection object
      def self.props(fedora_collection, notifier: nil)
        new(fedora_collection, notifier: notifier).props
      end

      def initialize(fedora_collection, notifier: nil)
        @fedora_collection = fedora_collection
        @notifier = notifier
      end

      def props
        {
          externalIdentifier: fedora_collection.pid,
          type: Cocina::Models::Vocab.collection,
          label: fedora_collection.label,
          version: fedora_collection.current_version.to_i,
          administrative: FromFedora::Administrative.props(fedora_collection),
          access: CollectionAccess.props(fedora_collection.rightsMetadata)
        }.tap do |props|
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_collection.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder, mods: fedora_collection.descMetadata.ng_xml, druid: fedora_collection.pid, notifier: notifier)
          props[:description] = description unless description.nil?
          identification = FromFedora::Identification.props(fedora_collection)
          props[:identification] = identification unless identification.empty?
        end
      end

      private

      attr_reader :fedora_collection, :notifier
    end
  end
end
