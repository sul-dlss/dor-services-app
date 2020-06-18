# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina DRO objects from Fedora objects
    class DRO
      # @param [Dor::Item,Dor::Etd] item
      # @return [Hash] a hash that can be mapped to a cocina model
      def self.props(item)
        new(item).props
      end

      def initialize(item)
        @item = item
      end

      # @raises [SolrConnectionError]
      def props
        {
          externalIdentifier: item.pid,
          type: dro_type,
          # Label may have been truncated, so prefer objectLabel.
          label: item.objectLabel.first || item.label,
          version: item.current_version.to_i,
          administrative: FromFedora::Administrative.props(item),
          access: DROAccess.props(item),
          structural: DroStructural.props(item)
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

      def dro_type
        case item.contentMetadata.contentType.first
        when 'image'
          if AdministrativeTags.content_type(pid: item.pid).first =~ /^Manuscript/
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
