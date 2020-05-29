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
        { title: [{ status: 'primary', value: TitleMapper.build(item) }] }.tap do |desc|
          desc[:note] = notes if notes.present?
        end
      end

      private

      attr_reader :item

      def notes
        @notes ||= [].tap do |items|
          items << original_url if original_url
          items << abstract if abstract
        end
      end

      def abstract
        return if item.descMetadata.abstract.blank?

        @abstract ||= { type: 'summary', value: item.descMetadata.abstract.first }
      end

      # TODO: Figure out how to encode displayLabel https://github.com/sul-dlss/dor-services-app/issues/849#issuecomment-635713964
      def original_url
        val = item.descMetadata.ng_xml.xpath('//mods:note[@type="system details"][@displayLabel="Original site"]', mods: Dor::DescMetadataDS::MODS_NS).first
        { type: 'system details', value: val.content } if val
      end
    end
  end
end
