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
      def self.dro_type(fedora_item)
        return Cocina::Models::Vocab.agreement if fedora_item.is_a? Dor::Agreement

        case fedora_item.contentMetadata.contentType.first
        when 'image'
          if /^Manuscript/.match?(AdministrativeTags.content_type(pid: fedora_item.pid).first)
            Cocina::Models::Vocab.manuscript
          else
            Cocina::Models::Vocab.image
          end
        when 'book'
          Cocina::Models::Vocab.book
        when 'media'
          Cocina::Models::Vocab.media
        when 'map'
          Cocina::Models::Vocab.map
        when 'geo'
          Cocina::Models::Vocab.geo
        when 'webarchive-seed'
          Cocina::Models::Vocab.webarchive_seed
        when '3d'
          Cocina::Models::Vocab.three_dimensional
        when 'document'
          Cocina::Models::Vocab.document
        when 'file', nil
          Cocina::Models::Vocab.object
        else
          raise "Unknown content type #{fedora_item.contentMetadata.contentType.first}"
        end
      end

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
          # Label may have been truncated, so prefer objectLabel.
          label: fedora_item.objectLabel.first || fedora_item.label,
          version: fedora_item.current_version.to_i,
          administrative: FromFedora::Administrative.props(fedora_item),
          access: DROAccess.props(fedora_item.rightsMetadata, fedora_item.embargoMetadata),
          structural: DroStructural.props(fedora_item, type: type)
        }.tap do |props|
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: fedora_item.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder,
                                                      mods: fedora_item.descMetadata.ng_xml,
                                                      druid: fedora_item.pid,
                                                      notifier: notifier)
          props[:description] = description unless description.nil?
          props[:geographic] = { iso19139: fedora_item.geoMetadata.content } if type == Cocina::Models::Vocab.geo
          identification = FromFedora::Identification.props(fedora_item)
          props[:identification] = identification unless identification.empty?
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :fedora_item, :notifier
    end
  end
end
