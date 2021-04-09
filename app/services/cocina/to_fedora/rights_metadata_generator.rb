# frozen_string_literal: true

module Cocina
  module ToFedora
    # Builds the rightsMetadata xml from cocina
    class RightsMetadataGenerator
      # @param [Dor::Item] item the DOR item
      # @param [Cocina::Model::RequestDRO] object the cocina model of the DRO
      def self.generate(item:, object:)
        new(item: item, object: object).generate
      end

      def initialize(item:, object:)
        @item = item
        @object = object
      end

      # Adapted copypasta from https://github.com/sul-dlss/dor-services/blob/main/lib/dor/datastreams/rights_metadata_ds.rb
      def generate
        rightsMetadata.ng_xml_will_change!

        # NOTE: The discover node is either 'none' for a dark object or 'world' for any other rights option
        label = rights_type == 'dark' ? 'none' : 'world'
        rights_xml.search("//rightsMetadata/access[@type='discover' and not(file)]/machine").each do |node|
          node.children.remove
          node.add_child Nokogiri::XML::Node.new(label, rights_xml)
        end

        # The read node varies by rights option
        rights_xml.search("//rightsMetadata/access[@type='read' and not(file)]").each.with_index do |node, index|
          node.children.remove
          machine_node = Nokogiri::XML::Node.new('machine', rights_xml)
          node.add_child(machine_node)
          if rights_type.start_with?('world')
            world_node = Nokogiri::XML::Node.new('world', rights_xml)
            world_node.set_attribute('rule', 'no-download') if rights_type.end_with?('-nd')
            machine_node.add_child(world_node)
          elsif rights_type.start_with?('stanford')
            group_node = Nokogiri::XML::Node.new('group', rights_xml)
            group_node.content = 'stanford'
            group_node.set_attribute('rule', 'no-download') if rights_type.end_with?('-nd')
            machine_node.add_child(group_node)
          elsif rights_type.start_with?('loc:')
            loc_node = Nokogiri::XML::Node.new('location', rights_xml)
            loc_node.content = rights_type.split(':').last
            machine_node.add_child(loc_node)
          elsif rights_type.start_with?('cdl')
            cdl_node = Nokogiri::XML::Node.new('cdl', rights_xml)
            group_node = Nokogiri::XML::Node.new('group', cdl_node)
            group_node.content = 'stanford'
            group_node.set_attribute('rule', 'no-download')
            cdl_node.add_child(group_node)
            machine_node.add_child(cdl_node)
          else # we know it is none or dark by the argument filter (first line)
            machine_node.add_child Nokogiri::XML::Node.new('none', rights_xml)
          end

          # Append file-specific rights to the first `access@type='read'` node
          # if the object is a DRO; collections and APOs don't directly contain files
          if object.dro? && index.zero?
            # Remove file-specific rights from XML (because we will be
            # regenerating them from Cocina)
            rights_xml.search("//rightsMetadata/access[@type='read' and file]").map(&:remove)

            file_specific_rights = generate_file_specific_rights
            node.add_next_sibling(file_specific_rights) unless file_specific_rights.empty?
          end
        end

        rights_xml.to_xml
      end

      private

      attr_reader :item, :object

      delegate :rightsMetadata, to: :item
      delegate :access, to: :object

      def rights_xml
        rightsMetadata.ng_xml
      end

      def rights_type
        return 'cdl-stanford-nd' if access.respond_to?(:controlledDigitalLending) && access.controlledDigitalLending

        case access.access
        when 'location-based'
          "loc:#{access.readLocation}"
        when 'citation-only'
          'none'
        when 'dark'
          'dark'
        else
          return "#{access.access}-nd" if access.respond_to?(:download) && access.download == 'none'

          access.access
        end
      end

      def generate_file_specific_rights
        Nokogiri::XML::NodeSet.new(rights_xml).tap do |node_set|
          file_sets = Array(object.structural&.contains)
          next if file_sets.empty?

          file_sets.each do |file_set|
            files = Array(file_set.structural&.contains)
            next if files.empty?

            files.each do |file|
              file_specific_rights = file.access.to_h.slice(:access, :download)
              # Skip if file has same rights as item,
              next if file_specific_rights == item_defaults

              rights_to_add = rights_to_add_for(file_specific_rights)
              # unique_rights_values = rights_to_add.values.uniq.sort

              # unless unique_rights_values.in?([['world'], ['stanford'], ['dark', 'none']])
              #   Honeybadger.notify('Found file-specific rights that cannot be handled yet',
              #                      context: { rights: rights_to_add, druid: item.pid })
              #   next
              # end

              node_set << file_access_node(file, rights_to_add) # unique_rights_values.first)
            end
          end
        end
      end

      # It's too bad Rails deprecated `Hash#diff`
      def rights_to_add_for(file_specific_rights)
        file_specific_rights.tap do |file_rights|
          file_rights.each_key do |access_key|
            file_rights.except!(access_key) if item_defaults[access_key] == file_rights[access_key]
          end
        end
      end

      # NOTE: See note above about not handling use cases beyond adding world & stanford access
      def file_access_node(file, access_level)
        Nokogiri::XML::Node.new('access', rights_xml).tap do |access_node|
          machine_node = Nokogiri::XML::Node.new('machine', rights_xml)
          access_level_nodes_for(access_level).each do |access_level_node|
            machine_node.add_child(access_level_node)
          end
          file_node = Nokogiri::XML::Node.new('file', rights_xml)
          file_node.content = file.filename
          access_node.set_attribute('type', 'read')
          access_node.add_child(file_node)
          access_node.add_child(machine_node)
        end
      end

      def access_level_nodes_for(access_level)
        Nokogiri::XML::NodeSet.new(rights_xml).tap do |node_set|
          access_node = case access_level[:access]
                        when 'world'
                          Nokogiri::XML::Node.new('world', rights_xml)
                        when 'stanford'
                          Nokogiri::XML::Node.new('group', rights_xml) do |node|
                            node.content = 'stanford'
                          end
                        when 'dark'
                          Nokogiri::XML::Node.new('none', rights_xml)
                        end
          download_node = case access_level[:download]
                          when 'world'
                            case access_level[:access]
                            when 'world'
                              nil # already handled in access node
                            when 'stanford'
                              # todo
                            when 'dark'
                              # todo
                            end
                          when 'stanford'
                            case access_level[:access]
                            when 'world'
                            # todo
                            when 'stanford'
                              nil # already handled in access node
                            when 'dark'
                              # todo
                            end
                          when 'none'
                            case access_level[:access]
                            when 'world'
                            # todo
                            when 'stanford'
                            # todo
                            when 'dark'
                              nil # already handled in access node
                            end
                          end
          node_set << access_node if access_node
        end
      end

      def item_defaults
        access.to_h.slice(:access, :download)
      end

      def dark_access
        { access: 'dark', download: 'none' }
      end
    end
  end
end
