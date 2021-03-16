# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina DRO objects from Fedora objects
    class DRO
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

      # @raises [SolrConnectionError]
      # rubocop:disable Metrics/AbcSize
      def props
        {
          externalIdentifier: item.pid,
          type: dro_type,
          # Label may have been truncated, so prefer objectLabel.
          label: item.objectLabel.first || item.label,
          version: item.current_version.to_i,
          administrative: FromFedora::Administrative.props(item),
          access: DROAccess.props(item),
          structural: DroStructural.props(item, type: dro_type)
        }.tap do |props|
          title_builder = FromFedora::Descriptive::TitleBuilderStrategy.find(label: item.label)
          description = FromFedora::Descriptive.props(title_builder: title_builder,
                                                      mods: item.descMetadata.ng_xml,
                                                      druid: item.pid,
                                                      notifier: notifier)
          props[:description] = description unless description.nil?
          props[:geographic] = { iso19139: item.geoMetadata.content } if dro_type == Cocina::Models::Vocab.geo
          identification = FromFedora::Identification.props(item)
          identification[:catalogLinks] = [{ catalog: 'symphony', catalogRecordId: item.catkey }] if item.catkey
          props[:identification] = identification unless identification.empty?
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :item, :notifier

      def dro_type
        case item.contentMetadata.contentType.first
        when 'image'
          if /^Manuscript/.match?(AdministrativeTags.content_type(pid: item.pid).first)
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
          raise "Unknown content type #{item.contentMetadata.contentType.first}"
        end
      end
    end
  end
end
