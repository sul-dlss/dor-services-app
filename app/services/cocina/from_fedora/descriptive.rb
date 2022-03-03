# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina Descriptive objects from Fedora objects
    class Descriptive
      DESC_METADATA_NS = 'http://www.loc.gov/mods/v3'
      XLINK_NS = 'http://www.w3.org/1999/xlink'

      # @param [#build] title_builder
      # @param [Nokogiri::XML] mods
      # @param [String] druid
      # @oaram [String] label
      # @param [Cocina::FromFedora::DataErrorNotifier] notifier
      # @return [Hash] a hash that can be mapped to a cocina descriptive model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def self.props(mods:, druid:, label:, title_builder: Titles, notifier: nil)
        new(title_builder: title_builder, mods: mods, druid: druid, label: label, notifier: notifier).props
      end

      def initialize(title_builder:, mods:, label:, druid:, notifier:)
        @title_builder = title_builder
        @ng_xml = mods
        @notifier = notifier || DataErrorNotifier.new(druid: druid)
        @druid = druid
        @label = label
      end

      # @return [Hash] a hash that can be mapped to a cocina descriptive model
      # @raises [Cocina::Mapper::InvalidDescMetadata] if some assumption about descMetadata is violated
      def props
        return nil if ng_xml.root.nil?

        check_altrepgroups
        check_version
        props = DescriptiveBuilder.build(title_builder: title_builder,
                                         resource_element: ng_xml.root,
                                         notifier: notifier,
                                         purl: druid ? ::Purl.for(druid: druid) : nil)
        props[:title] = [{ value: label }] unless props.key?(:title)
        props
      end

      private

      attr_reader :title_builder, :ng_xml, :notifier, :druid, :label

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

        # altRepGroups can have the same script, e.g. Latn for English and French
        return false if scripts.size == 1

        true
      end
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      def check_version
        match = /MODS version (\d\.\d)/.match(ng_xml.root.at('//mods:recordInfo/mods:recordOrigin', mods: DESC_METADATA_NS)&.content)

        return unless match

        notifier.warn('MODS version mismatch') if match[1] != ng_xml.root['version']
      end
    end
  end
end
