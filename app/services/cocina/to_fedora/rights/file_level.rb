# frozen_string_literal: true

module Cocina
  module ToFedora
    class Rights
      # Builds the rightsMetadata xml from cocina for a file
      class FileLevel
        # @param [Nokogiri::XML::Document] rights_xml an XML document representing rights metadata
        # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
        # @param [Cocina::Models::DROStructural] structural structural metadata in Cocina
        # @return [Array<Nokogiri::XML::Element>]
        def self.generate(rights_xml:, access:, structural:)
          new(rights_xml: rights_xml, access: access, structural: structural).generate
        end

        # @param [Nokogiri::XML::Document] rights_xml an XML document representing rights metadata
        # @param [Cocina::Models::DROAccess, Cocina::Models::Access] access access/rights metadata in Cocina
        # @param [Cocina::Models::DROStructural] structural structural metadata in Cocina
        def initialize(rights_xml:, access:, structural:)
          @rights_xml = rights_xml
          @access = access
          @structural = structural
        end

        # @return [Array<Nokogiri::XML::Element>]
        def generate
          [].tap do |nodes|
            file_sets.each do |file_set|
              file_set.structural.contains.each do |file|
                next unless file_access_different_than_item_access?(file.access)

                read_access_node = Nokogiri::XML::Node.new('access', rights_xml).tap do |access_node|
                  access_node.set_attribute('type', 'read')
                  file_node = Nokogiri::XML::Node.new('file', rights_xml)
                  file_node.content = file.filename
                  access_node.add_child(file_node)
                end

                read_access_node.add_child(read_machine_node(file.access))

                if (download_node = download_machine_node(file.access))
                  read_access_node.add_child(download_node)
                end

                nodes << read_access_node
              end
            end
          end
        end

        private

        attr_reader :rights_xml, :access, :structural

        def file_sets
          Array(structural&.contains)
        end

        def file_access_different_than_item_access?(file_access)
          file_access.to_h.slice(*file_access_props) != access.to_h.slice(*file_access_props)
        end

        def file_access_props
          %i[access controlledDigitalLending download readLocation]
        end

        def read_machine_node(file_access)
          Nokogiri::XML::Node.new('machine', rights_xml).tap do |machine_node| # rubocop:disable Metrics/BlockLength
            read_access_level_node =
              if cdl_access?(file_access)
                cdl_node = Nokogiri::XML::Node.new('cdl', rights_xml)
                group_node = Nokogiri::XML::Node.new('group', cdl_node)
                group_node.content = 'stanford'
                group_node.set_attribute('rule', 'no-download')
                cdl_node.add_child(group_node)
                cdl_node
              elsif world_read_access?(file_access)
                world_node = Nokogiri::XML::Node.new('world', rights_xml)
                world_node.set_attribute('rule', 'no-download') if no_download?(file_access) || location_based_download?(file_access) || stanford_download?(file_access)
                world_node
              elsif stanford_read_access?(file_access)
                group_node = Nokogiri::XML::Node.new('group', rights_xml)
                group_node.content = 'stanford'
                group_node.set_attribute('rule', 'no-download') if no_download?(file_access) || location_based_download?(file_access)
                group_node
              elsif location_based_access?(file_access)
                loc_node = Nokogiri::XML::Node.new('location', rights_xml)
                loc_node.content = file_access.readLocation
                loc_node.set_attribute('rule', 'no-download') if no_download?(file_access)
                loc_node
              else # we know it is citation-only or dark at this point
                Nokogiri::XML::Node.new('none', rights_xml)
              end
            machine_node.add_child(read_access_level_node)
          end
        end

        def download_machine_node(file_access)
          return unless (location_based_download?(file_access) && (stanford_read_access?(file_access) || world_read_access?(file_access))) ||
                        (stanford_download?(file_access) && world_read_access?(file_access))

          Nokogiri::XML::Node.new('machine', rights_xml).tap do |machine_node|
            download_access_level_node =
              if location_based_download?(file_access)
                loc_node = Nokogiri::XML::Node.new('location', rights_xml)
                loc_node.content = file_access.readLocation
                loc_node
              elsif stanford_download?(file_access)
                group_node = Nokogiri::XML::Node.new('group', rights_xml)
                group_node.content = 'stanford'
                group_node
              end

            machine_node.add_child(download_access_level_node)
          end
        end

        def world_read_access?(file_access)
          file_access.access == 'world'
        end

        def stanford_read_access?(file_access)
          file_access.access == 'stanford'
        end

        def cdl_access?(file_access)
          file_access.try(:controlledDigitalLending)
        end

        def location_based_access?(file_access)
          file_access.access == 'location-based' && file_access.try(:readLocation)
        end

        def no_download?(file_access)
          file_access.try(:download) == 'none'
        end

        def stanford_download?(file_access)
          file_access.try(:download) == 'stanford'
        end

        def location_based_download?(file_access)
          file_access.try(:download) == 'location-based' && file_access.try(:readLocation)
        end
      end
    end
  end
end
