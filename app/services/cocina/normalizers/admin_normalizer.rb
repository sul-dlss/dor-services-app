# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object adminMetadata datastream, accounting for differences between Fedora and cocina that are valid but differ when round-tripping.
    class AdminNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] admin_ng_xml admin metadata XML to be normalized
      # @return [Nokogiri::Document] normalized admin metadata xml
      def self.normalize(admin_ng_xml:)
        new(admin_ng_xml: admin_ng_xml).normalize
      end

      def initialize(admin_ng_xml:)
        @ng_xml = admin_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # following pattern from other normalizers
      end

      def normalize
        remove_desc_metadata_format_mods
        remove_empty_registration_and_dissemination
        remove_empty_dissemination_workflow
        remove_object_id_attr
        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      # removes nodes like this: <descMetadata><format>MODS</format><descMetadata>
      def remove_desc_metadata_format_mods
        ng_xml.xpath('/administrativeMetadata/descMetadata/format[text()="MODS"]').each { |node| node.parent.remove }
      end

      # removes empty nodes like this: <registration/> or <dissemination/> or <dissemination><workflow id="" /></dissemination>
      def remove_empty_registration_and_dissemination
        ng_xml.xpath('/administrativeMetadata/registration[not(node())]').each(&:remove)
        ng_xml.xpath('/administrativeMetadata/dissemination[not(node())]').each(&:remove)
        ng_xml.xpath('/administrativeMetadata/dissemination/workflow[@id=""]').each { |node| node.parent.remove }
      end

      # remove dissemination workflow node with empty id attribute and then remove dissemination node
      def remove_empty_dissemination_workflow
        ng_xml.xpath('/administrativeMetadata/dissemination/workflow[@id=""]').each(&:remove)
        ng_xml.xpath('/administrativeMetadata/dissemination[not(*)]').each(&:remove)
      end

      def remove_object_id_attr
        ng_xml.xpath('/administrativeMetadata[@objectId]').each do |node|
          node.delete('objectId')
        end
      end
    end
  end
end
