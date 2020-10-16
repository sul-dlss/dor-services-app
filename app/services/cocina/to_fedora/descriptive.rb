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

      def transform
        Nokogiri::XML::Builder.new do |xml|
          xml.mods('xmlns' => 'http://www.loc.gov/mods/v3',
                   'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
                   'version' => '3.6',
                   'xsi:schemaLocation' => 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd') do
            Descriptive::Title.write(xml: xml, titles: descriptive.title)
            Descriptive::Contributor.write(xml: xml, contributors: descriptive.contributor)
            Descriptive::Form.write(xml: xml, forms: descriptive.form)
            Descriptive::Language.write(xml: xml, languages: descriptive.language)
            Descriptive::Note.write(xml: xml, notes: descriptive.note)
            Descriptive::Subject.write(xml: xml, subjects: descriptive.subject, forms: descriptive.form)
            Descriptive::Event.write(xml: xml, events: descriptive.event)
            Descriptive::Identifier.write(xml: xml, identifiers: descriptive.identifier)
            Descriptive::AdminMetadata.write(xml: xml, admin_metadata: descriptive.adminMetadata)
            Descriptive::Geographic.write(xml: xml, geo: descriptive.geographic)
          end
        end
      end

      private

      attr_reader :descriptive
    end
  end
end
