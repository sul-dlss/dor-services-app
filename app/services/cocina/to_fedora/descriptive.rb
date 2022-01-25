# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.descriptive schema to the
    # Fedora 3 data model descMetadata
    class Descriptive
      # @param [Cocina::Models::Description] descriptive
      # @param [string] druid
      # @return [Nokogiri::XML::Document]
      def self.transform(descriptive, druid)
        new(descriptive, druid).transform
      end

      def initialize(descriptive, druid)
        @descriptive = descriptive
        @druid = druid
      end

      # @return [Nokogiri::XML::Document]
      def transform
        Nokogiri::XML::Builder.new(encoding: 'UTF-8') do |xml|
          xml.mods(mods_attributes) do
            Descriptive::DescriptiveWriter.write(xml: xml, descriptive: descriptive, druid: druid)
          end
        end.doc
      end

      private

      attr_reader :descriptive, :druid

      def mods_version
        @mods_version ||= begin
          notes = descriptive.adminMetadata&.note || []
          notes.select { |note| note.type == 'record origin' }.each do |note|
            match = /MODS version (\d\.\d)/.match(note.value)
            return match[1] if match
          end
          '3.7'
        end
      end

      def mods_attributes
        {
          'xmlns' => 'http://www.loc.gov/mods/v3',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
          'xmlns:xlink' => 'http://www.w3.org/1999/xlink',
          'version' => mods_version,
          'xsi:schemaLocation' => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-#{mods_version.sub('.', '-')}.xsd"
        }
      end
    end
  end
end
