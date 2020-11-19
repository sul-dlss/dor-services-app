# frozen_string_literal: true

module Cocina
  module ToFedora
    class Descriptive
      # Maps descriptive resource from cocina to MODS XML
      class DescriptiveWriter
        # @params [Nokogiri::XML::Builder] xml
        # @param [Cocina::Models::Description] descriptive
        # @param [string] druid
        def self.write(xml:, descriptive:, druid:)
          Title.write(xml: xml, titles: descriptive.title) if descriptive.title
          Contributor.write(xml: xml, contributors: descriptive.contributor)
          Form.write(xml: xml, forms: descriptive.form)
          Language.write(xml: xml, languages: descriptive.language)
          Note.write(xml: xml, notes: descriptive.note)
          Subject.write(xml: xml, subjects: descriptive.subject, forms: descriptive.form)
          Event.write(xml: xml, events: descriptive.event)
          Identifier.write(xml: xml, identifiers: descriptive.identifier)
          AdminMetadata.write(xml: xml, admin_metadata: descriptive.adminMetadata) if descriptive.respond_to?(:adminMetadata)
          RelatedResource.write(xml: xml, related_resources: descriptive.relatedResource, druid: druid) if descriptive.respond_to?(:relatedResource)
          Geographic.write(xml: xml, geos: descriptive.geographic, druid: druid) if descriptive.respond_to?(:geographic)
        end
      end
    end
  end
end
