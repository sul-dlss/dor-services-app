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
        @druid = druid
      end

      # @return [Hash] a hash that can be mapped to a cocina descriptive model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def props
        check_altrepgroups
        DescriptiveBuilder.build(title_builder: title_builder,
                                 resource_element: ng_xml.root,
                                 notifier: notifier,
                                 purl: druid ? Purl.purl_for(druid) : nil)
      end

      private

      attr_reader :title_builder, :ng_xml, :notifier, :druid

      def check_altrepgroups
        ng_xml.xpath('//mods:*[@altRepGroup]', mods: DESC_METADATA_NS)
              .group_by { |node| node['altRepGroup'] }
              .values
              .select { |nodes| nodes.size > 1 }
              .each do |nodes|
          notifier.warn('Unpaired altRepGroup') if altrepgroup_error?(nodes)
        end
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def altrepgroup_error?(nodes)
        return true if nodes.map(&:name).uniq.size != 1

        # For subjects, script/lang may be in child so looking in both locations.
        scripts = nodes.map { |node| node['script'].presence || node.elements.first&.attribute('script')&.presence }.uniq
        # Every node has a different script.
        return false if scripts.size == nodes.size

        langs = nodes.map { |node| node['lang'].presence || node.elements.first&.attribute('lang')&.presence }.uniq
        # Every node has a different lang.
        return false if langs.size == nodes.size

        # No scripts or langs
        return false if scripts.compact.empty? && langs.compact.empty?

        true
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def purl
        "http://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
      end
    end
  end
end
