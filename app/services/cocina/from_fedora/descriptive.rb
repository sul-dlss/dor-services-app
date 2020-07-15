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
          desc[:note] = NotesMapper.build(item)
          desc[:language] = LanguageMapper.build(item)
          desc[:contributor] = ContributorMapper.build(item)
          desc[:form] = FormMapper.build(item)
        end
      end

      private

      attr_reader :item

    end
  end
end
