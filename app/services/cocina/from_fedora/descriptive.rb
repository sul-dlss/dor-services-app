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
        ng_xml = item.descMetadata.ng_xml
        titles = if item.label == 'Hydrus'
                   # Some hydrus items don't have titles, so using label. See https://github.com/sul-dlss/hydrus/issues/421
                   [{ value: 'Hydrus' }]
                 else
                   Titles.build(ng_xml)
                 end

        note = Notes.build(ng_xml)
        language = Language.build(ng_xml)
        contributor = Contributor.build(ng_xml)
        form = Form.build(ng_xml)
        { title: titles }.tap do |desc|
          desc[:note] = note unless note.empty?
          desc[:language] = language unless language.empty?
          desc[:contributor] = contributor unless contributor.empty?
          desc[:form] = form unless form.empty?
        end
      end

      private

      attr_reader :item
    end
  end
end
