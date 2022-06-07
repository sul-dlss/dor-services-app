# frozen_string_literal: true

module Cocina
  module ToXml
    # Builds the access-related xml from cocina (for rightsMetadataDS and embargoDS)
    class AccessGenerator
      # @param [Nokogiri::XML::Element] root Element that is the root of the access assertions.
      # @param [Cocina::Models::DROAccess, Cocina::Models::CollectionAccess, Cocina::Models::Embargo] access access/rights metadata in Cocina
      # @param [Cocina::Models::DROStructural] structural structural metadata in Cocina
      # @return [String] Fedora rights metadata XML
      def self.generate(root:, access:, structural: nil)
        new(root:, access:, structural:).generate
      end

      def initialize(root:, access:, structural:)
        @root = root
        @access = access
        @structural = structural
      end

      # @return [String] Fedora rights metadata XML
      def generate
        return if access.nil?

        # Remove existing access nodes to begin rebuilding them from Cocina
        root.search('//access').each(&:remove)

        Rights::ObjectLevel.generate(root:, access:).each do |object_access_node|
          root.add_child(object_access_node)
        end

        if structural
          Rights::FileLevel.generate(root:, access:, structural:).each do |file_access_node|
            root.add_child(file_access_node)
          end
        end

        root.to_xml
      end

      private

      attr_reader :root, :access, :structural
    end
  end
end
