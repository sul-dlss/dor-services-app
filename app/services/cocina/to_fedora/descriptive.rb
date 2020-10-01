# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.descriptive schema to the
    # Fedora 3 data model descMetadata
    class Descriptive
      TAG_NAME = {
        'nonsorting characters' => :nonSort,
        'main title' => :title,
        'part name' => 'partName',
        'part number' => 'partNumber'
      }.freeze
      # @param [Cocina::Models::Description] descriptive
      # @return [Nokogiri::XML::Document]
      def self.transform(descriptive)
        new(descriptive).transform
      end

      def initialize(descriptive)
        @descriptive = descriptive
      end

      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/BlockLength
      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def transform
        Nokogiri::XML::Builder.new do |xml|
          xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
                   'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                   'version' => '3.6',
                   'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
            descriptive.title.each_with_index do |title, alt_rep_group|
              if title.parallelValue
                title.parallelValue.each_with_index do |descriptive_value, i|
                  title_info_attrs = { altRepGroup: alt_rep_group }
                  title_info_attrs[:lang] = descriptive_value.valueLanguage.code if descriptive_value.valueLanguage
                  title_info_attrs[:usage] = 'primary' if i.zero?
                  title_info_attrs[:type] = 'translated' if i.positive?

                  xml.titleInfo(title_info_attrs) do
                    descriptive_value.structuredValue&.each do |component|
                      xml.public_send(TAG_NAME.fetch(component.type), component.value) if component.type
                    end

                    xml.title(descriptive_value.value) if descriptive_value.value
                  end
                end
              elsif title.structuredValue
                title_info_attrs = {}
                title_info_attrs[:usage] = 'primary' if title.status == 'primary'
                title_info_attrs[:type] = title.type if title.type

                xml.titleInfo(title_info_attrs) do
                  title.structuredValue&.each do |component|
                    xml.public_send(TAG_NAME.fetch(component.type), component.value) if component.type
                  end
                end
              elsif title.value
                title_info_attrs = {}
                title_info_attrs[:usage] = 'primary' if title.status == 'primary'
                title_info_attrs[:type] = title.type if title.type

                xml.titleInfo(title_info_attrs) do
                  xml.title(title.value)
                end
              end
            end
          end
        end
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/BlockLength
      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity

      private

      attr_reader :descriptive
    end
  end
end
