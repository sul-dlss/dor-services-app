# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

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
          desc[:language] = language if language.present?
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
        val = item.descMetadata.ng_xml.xpath('//mods:note[@type="system details"][@displayLabel="Original site"]', mods: DESC_METADATA_NS).first
        { type: 'system details', value: val.content } if val
      end

      def language
        # TODO: Add uri, source.code, source.uri
        @language ||= [].tap do |langs|
          item.descMetadata.ng_xml.xpath('//mods:language', mods: DESC_METADATA_NS).each do |lang|
            val = lang.xpath('./mods:languageTerm[@type="text"]', mods: DESC_METADATA_NS).first
            code = lang.xpath('./mods:languageTerm[@type="code"]', mods: DESC_METADATA_NS).first
            break if val.blank?

            langs << {
              value: val.content,
              code: code.content,
              uri: val.attribute('valueURI').value,
              source: {
                code: val.attribute('authority').value,
                uri: val.attribute('authorityURI').value
              }
            }
          end
        end
      end
    end
  end
end
