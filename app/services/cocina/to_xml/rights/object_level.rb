# frozen_string_literal: true

module Cocina
  module ToXml
    module Rights
      # Builds the rightsMetadata xml from cocina for an object (item/collection)
      class ObjectLevel
        # @param [Nokogiri::XML::Element] root Element that is the root of the access assertions.
        # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
        # @return [Array<Nokogiri::XML::Element>]
        def self.generate(root:, access:)
          new(root:, access:).generate
        end

        # @param [Nokogiri::XML::Element] root Element that is the root of the access assertions.
        # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
        def initialize(root:, access:)
          @root = root
          @access = access
        end

        # @return [Array<Nokogiri::XML::Element>]
        def generate
          [].tap do |nodes|
            # Add discover access node
            nodes << discover_access_node

            # Add read access node
            nodes << read_access_node

            # Add download access node if needed
            nodes << download_access_node if download_access_node
          end
        end

        private

        attr_reader :root, :access

        def discover_access_node
          Nokogiri::XML::Node.new('access', document).tap do |access_node|
            access_node.set_attribute('type', 'discover')
            machine_node = Nokogiri::XML::Node.new('machine', document)
            access_level_node = Nokogiri::XML::Node.new(discover_label, document)
            machine_node.add_child(access_level_node)
            access_node.add_child(machine_node)
          end
        end

        # NOTE: The discover node is either 'none' for a dark object or 'world' for any other rights option
        def discover_label
          return 'none' if access.view == 'dark'

          'world'
        end

        def read_access_node
          Nokogiri::XML::Node.new('access', document).tap do |access_node|
            access_node.set_attribute('type', 'read')
            machine_node = Nokogiri::XML::Node.new('machine', document)
            machine_node.add_child(read_access_level_node)
            access_node.add_child(machine_node)
          end
        end

        def read_access_level_node
          if cdl_access?
            cdl_node = Nokogiri::XML::Node.new('cdl', document)
            group_node = Nokogiri::XML::Node.new('group', document)
            group_node.content = 'stanford'
            group_node.set_attribute('rule', 'no-download')
            cdl_node.add_child(group_node)
            cdl_node
          elsif world_read_access?
            world_node = Nokogiri::XML::Node.new('world', document)
            world_node.set_attribute('rule', 'no-download') if no_download? || location_based_download? || stanford_download?
            world_node
          elsif stanford_read_access?
            group_node = Nokogiri::XML::Node.new('group', document)
            group_node.content = 'stanford'
            group_node.set_attribute('rule', 'no-download') if no_download? || location_based_download?
            group_node
          elsif location_based_access?
            loc_node = Nokogiri::XML::Node.new('location', document)
            loc_node.content = access.location
            loc_node.set_attribute('rule', 'no-download') if no_download?
            loc_node
          else # we know it is citation-only or dark at this point
            Nokogiri::XML::Node.new('none', document)
          end
        end

        def download_access_node
          return unless (location_based_download? && (stanford_read_access? || world_read_access?)) ||
                        (stanford_download? && world_read_access?)

          Nokogiri::XML::Node.new('access', document).tap do |access_node|
            access_node.set_attribute('type', 'read')
            machine_node = Nokogiri::XML::Node.new('machine', document)
            machine_node.add_child(download_access_level_node)
            access_node.add_child(machine_node)
          end
        end

        def download_access_level_node
          if location_based_download?
            loc_node = Nokogiri::XML::Node.new('location', document)
            loc_node.content = access.location
            loc_node
          elsif stanford_download?
            group_node = Nokogiri::XML::Node.new('group', document)
            group_node.content = 'stanford'
            group_node
          end
        end

        def world_read_access?
          access.view == 'world'
        end

        def stanford_read_access?
          access.view == 'stanford'
        end

        def cdl_access?
          access.try(:controlledDigitalLending)
        end

        def location_based_access?
          access.view == 'location-based' && access.try(:location)
        end

        def no_download?
          access.try(:download) == 'none'
        end

        def stanford_download?
          access.try(:download) == 'stanford'
        end

        def location_based_download?
          access.try(:download) == 'location-based' && access.try(:location)
        end

        def document
          root.document
        end
      end
    end
  end
end
