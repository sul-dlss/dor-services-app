# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina::DRO object properties from Fedora objects
    class DRO
      # @param [Dor::Item,Dor::Etd,Dor::Agreement] fedora_item
      # @param [Cocina::FromFedora::DataErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a Cocina::DRO object
      def self.props(fedora_item, notifier: nil)
        new(fedora_item, notifier: notifier).props
      end

      # @param [Dor::Item,Dor::Etd,Dor::Agreement] fedora_item
      # @return [String] fedora_item's type
      # rubocop:disable Metrics/CyclomaticComplexity
      def self.dro_type(fedora_item)
        return Cocina::Models::ObjectType.agreement if fedora_item.is_a? Dor::Agreement

        case fedora_item.contentMetadata.contentType.first
        when 'image'
          if /^Manuscript/.match?(AdministrativeTags.content_type(identifier: fedora_item.pid).first)
            Cocina::Models::ObjectType.manuscript
          else
            Cocina::Models::ObjectType.image
          end
        when 'book'
          Cocina::Models::ObjectType.book
        when 'media'
          Cocina::Models::ObjectType.media
        when 'map'
          Cocina::Models::ObjectType.map
        when 'geo'
          Cocina::Models::ObjectType.geo
        when 'webarchive-seed'
          Cocina::Models::ObjectType.webarchive_seed
        when '3d'
          Cocina::Models::ObjectType.three_dimensional
        when 'document'
          Cocina::Models::ObjectType.document
        when 'file', nil
          Cocina::Models::ObjectType.object
        else
          raise "Unknown content type #{fedora_item.contentMetadata.contentType.first}"
        end
      rescue Rubydora::FedoraInvalidRequest, StandardError => e
        new_message = "Unable to get contentType - is contentMetadata DS empty? #{e.message}"
        raise e.class, new_message, e.backtrace
      end
      # rubocop:enable Metrics/CyclomaticComplexity

      def initialize(fedora_item, notifier: nil)
        @fedora_item = fedora_item
        @notifier = notifier
      end

      # @raises [SolrConnectionError]
      # rubocop:disable Metrics/AbcSize
      def props
        type = DRO.dro_type(fedora_item)
        {
          externalIdentifier: fedora_item.pid,
          type: type,
          label: cocina_label,
          version: fedora_item.current_version.to_i,
          administrative: FromFedora::Administrative.props(fedora_item),
          access: DROAccess.props(fedora_item.rightsMetadata, fedora_item.embargoMetadata),
          structural: DroStructural.props(fedora_item, type: type, notifier: notifier)
        }.tap do |props|
          title_builder = Models::Mapping::FromMods::TitleBuilderStrategy.find(label: fedora_item.label)
          description = Models::Mapping::FromMods::Description.props(title_builder: title_builder,
                                                                     mods: fedora_item.descMetadata.ng_xml,
                                                                     druid: fedora_item.pid,
                                                                     label: cocina_label,
                                                                     notifier: notifier)
          props[:description] = description
          props[:geographic] = { iso19139: fedora_item.geoMetadata.content } if type == Cocina::Models::ObjectType.geo
          identification = FromFedora::Identification.props(fedora_item)
          props[:identification] = identification unless identification.empty?
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :fedora_item, :notifier

      def cocina_label
        @cocina_label ||= Label.for(fedora_item)
      end
    end
  end
end
