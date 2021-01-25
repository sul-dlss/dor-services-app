# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = Dor::DescMetadataDS::MODS_NS

      # @param [#build] title_builder
      # @param [Nokogiri::XML] mods
      # @param [String] druid
      # @param [Cocina::FromFedora::DataErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a cocina descriptive model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def self.props(mods:, druid:, title_builder: Titles, notifier: nil)
        new(title_builder: title_builder, mods: mods, druid: druid, notifier: notifier).props
      end

      def initialize(title_builder:, mods:, druid:, notifier:)
        @title_builder = title_builder
        @ng_xml = mods
        @notifier = notifier || DataErrorNotifier.new(druid: druid)
      end

      # @return [Hash] a hash that can be mapped to a cocina descriptive model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def props
        check_altrepgroups
        DescriptiveBuilder.build(title_builder: title_builder, resource_element: ng_xml.root, notifier: notifier)
      end

      private

      attr_reader :title_builder, :ng_xml, :notifier

      def check_altrepgroups
        ng_xml.xpath('//mods:*[@altRepGroup]', mods: DESC_METADATA_NS)
              .group_by { |node| node['altRepGroup'] }
              .values
              .select { |nodes| nodes.size > 1 }
              .each do |nodes|
          notifier.warn('Bad altRepGroup') if altrepgroup_error?(nodes)
        end
      end

      def altrepgroup_error?(nodes)
        return true if nodes.map(&:name).uniq.size != 1

        scripts = nodes.map { |node| node['script'] }.uniq
        langs = nodes.map { |node| node['lang'] }.uniq
        return false if scripts.size == nodes.size || langs.size == nodes.size

        true
      end
    end
  end
end
