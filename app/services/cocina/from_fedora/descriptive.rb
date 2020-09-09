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
        note = Notes.build(item)
        language = Language.build(item)
        contributor = Contributor.build(item)
        form = Form.build(item)
        { title: [{ status: 'primary', value: TitleMapper.build(item) }] }.tap do |desc|
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
