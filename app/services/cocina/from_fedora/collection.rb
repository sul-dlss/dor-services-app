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
          type: Cocina::Models::ObjectType.collection,
          label: cocina_label,
          version: fedora_collection.current_version.to_i,
          administrative: FromFedora::Administrative.props(fedora_collection),
          access: CollectionAccess.props(fedora_collection.rightsMetadata),
          identification: FromFedora::Identification.props(fedora_collection)
        }.tap do |props|
          title_builder = Models::Mapping::FromMods::TitleBuilderStrategy.find(label: fedora_collection.label)
          description = Models::Mapping::FromMods::Description.props(title_builder: title_builder,
                                                                     mods: fedora_collection.descMetadata.ng_xml,
                                                                     druid: fedora_collection.pid,
                                                                     label: cocina_label,
                                                                     notifier: notifier)
          props[:description] = description unless description.nil?
        end
      end

      private

      attr_reader :fedora_collection, :notifier

      def cocina_label
        @cocina_label ||= Label.for(fedora_collection)
      end
    end
  end
end
