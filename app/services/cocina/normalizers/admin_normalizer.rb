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
        remove_desc_metadata_source
        remove_relationships
        remove_assembly_node
        remove_accessioning_node
        remove_empty_registration_and_dissemination
        remove_registration_collection_default_attr
        remove_object_id_attr
        remove_contacts
        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      # removes <descMetadata><format>MODS</format><descMetadata>
      def remove_desc_metadata_format_mods
        ng_xml.xpath('/administrativeMetadata/descMetadata/format[text()="MODS"]').each { |node| node.parent.remove }
      end

      # removes <descMetadata><source>whatevs</source><descMetadata>
      def remove_desc_metadata_source
        ng_xml.xpath('/administrativeMetadata/descMetadata/source').each { |node| node.parent.remove }
      end

      # we get this info from RELS-EXT
      def remove_relationships
        ng_xml.xpath('/administrativeMetadata/relationships').each(&:remove)
      end

      def remove_assembly_node
        ng_xml.xpath('/administrativeMetadata/assembly').each(&:remove)
      end

      def remove_accessioning_node
        ng_xml.xpath('/administrativeMetadata/accessioning').each(&:remove)
      end

      # removes:
      #   <registration/>
      #   <dissemination/>
      #   <dissemination><workflow id="" /></dissemination>
      def remove_empty_registration_and_dissemination
        ng_xml.xpath('/administrativeMetadata/registration[not(node())]').each(&:remove)
        ng_xml.xpath('/administrativeMetadata/dissemination/workflow[@id=""]').each { |node| node.parent.remove }
        ng_xml.xpath('/administrativeMetadata/dissemination[not(node())]').each(&:remove)
      end

      def remove_registration_collection_default_attr
        ng_xml.xpath('/administrativeMetadata/registration/collection/@default').each(&:remove)
      end

      def remove_object_id_attr
        ng_xml.xpath('/administrativeMetadata/@objectId').each(&:remove)
      end

      def remove_contacts
        ng_xml.xpath('/administrativeMetadata/contact').each(&:remove)
      end
    end
  end
end
