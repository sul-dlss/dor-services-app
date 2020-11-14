# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.descriptive schema to the
    # Fedora 3 data model descMetadata
    class Descriptive
      # @param [Cocina::Models::Description] descriptive
      # @return [Nokogiri::XML::Document]
      def self.transform(descriptive)
        new(descriptive).transform
      end

      def initialize(descriptive)
        @descriptive = descriptive
      end

      # rubocop:disable Metrics/AbcSize
      def transform
        Nokogiri::XML::Builder.new do |xml|
          xml.mods(namespaces) do
            Descriptive::Title.write(xml: xml, titles: descriptive.title)
            Descriptive::Contributor.write(xml: xml, contributors: descriptive.contributor)
            Descriptive::Form.write(xml: xml, forms: descriptive.form)
            Descriptive::Language.write(xml: xml, languages: descriptive.language)
            Descriptive::Note.write(xml: xml, notes: descriptive.note)
            Descriptive::Subject.write(xml: xml, subjects: descriptive.subject, forms: descriptive.form)
            Descriptive::Event.write(xml: xml, events: descriptive.event)
            Descriptive::Identifier.write(xml: xml, identifiers: descriptive.identifier)
            Descriptive::AdminMetadata.write(xml: xml, admin_metadata: descriptive.adminMetadata)
            Descriptive::RelatedResource.write(xml: xml, related_resources: descriptive.relatedResource)
            Descriptive::Geographic.write(xml: xml, geos: descriptive.geographic)
          end
        end
      end
      # rubocop:enable Metrics/AbcSize

      private

      attr_reader :descriptive

      def mods_version
        @mods_version ||= begin
          notes = descriptive.adminMetadata&.note || []
          notes.select { |note| note.type == 'record origin' }.each do |note|
            match = /MODS version (\d\.\d)/.match(note.value)
            return match[1] if match
          end
          '3.6'
        end
      end

      def namespaces
        {
          'xmlns' => 'http://www.loc.gov/mods/v3',
          'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
          'xmlns:rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#',
          'version' => mods_version,
          'xsi:schemaLocation' => "http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-#{mods_version.sub('.', '-')}.xsd"
        }
      end
    end
  end
end
