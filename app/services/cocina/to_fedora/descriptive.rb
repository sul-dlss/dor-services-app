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
      # @param [Cocina::Models::Descriptive] descriptive
      # @return [Nokogiri::XML::Document]
      def self.transform(descriptive)
        new(descriptive).transform
      end

      def initialize(descriptive)
        @descriptive = descriptive
      end

      def transform
        Nokogiri::XML::Builder.new do |xml|
          xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
                   'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                   'version' => '3.6',
                   'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
            descriptive.title.each do |title|
              title_info_attrs = {}
              title_info_attrs[:usage] = 'primary' if title.status == 'primary'
              title_info_attrs[:type] = title.type if title.type

              xml.titleInfo(title_info_attrs) do
                title.structuredValue&.each do |component|
                  xml.public_send(TAG_NAME.fetch(component.type), component.value) if component.type
                end

                xml.title(title.value) if title.value
              end
            end
          end
        end
      end

      private

      attr_reader :descriptive
    end
  end
end
