# frozen_string_literal: true

module Cocina
  module Normalizers
    # Normalizes a Fedora object roleMetadata datastream, accounting for differences between Fedora and cocina that are valid but differ when round-tripping.
    class RoleNormalizer
      include Cocina::Normalizers::Base

      # @param [Nokogiri::Document] role_ng_xml role metadata XML to be normalized
      # @return [Nokogiri::Document] normalized role metadata xml
      def self.normalize(role_ng_xml:)
        new(role_ng_xml: role_ng_xml).normalize
      end

      def initialize(role_ng_xml:)
        @ng_xml = role_ng_xml.dup
        @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=) # following pattern from other normalizers
      end

      def normalize
        normalize_identitifer_nodes
        regenerate_ng_xml(ng_xml.to_xml)
      end

      private

      attr_reader :ng_xml

      def normalize_identitifer_nodes
        # normalize <identifier> with type="person" and prefix "sunetid:" to an <identifier> with type="sunetid" with prefix removed
        ng_xml.xpath('//identifier[@type="person"]').each do |node|
          if node.text.starts_with?('sunetid:')
            node.content = node.content.delete_prefix('sunetid:')
            node['type'] = 'sunetid'
          end
        end
      end
    end
  end
end
