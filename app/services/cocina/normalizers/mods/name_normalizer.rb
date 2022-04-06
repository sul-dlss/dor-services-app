# frozen_string_literal: true

module Cocina
  module Normalizers
    module Mods
      # Normalizes a Fedora MODS document for name elements.
      class NameNormalizer
        # @param [Nokogiri::Document] mods_ng_xml MODS to be normalized
        # @return [Nokogiri::Document] normalized MODS
        def self.normalize(mods_ng_xml:)
          new(mods_ng_xml: mods_ng_xml).normalize
        end

        def initialize(mods_ng_xml:)
          @ng_xml = mods_ng_xml.dup
          @ng_xml.encoding = 'UTF-8'
        end

        def normalize
          normalize_parallel_name_role
          normalize_text_role_term
          normalize_role_term
          normalize_role # must be after normalize_role_term
          normalize_name
          normalize_dupes
          normalize_type
          normalize_name_part_type
          ng_xml
        end

        private

        attr_reader :ng_xml

        def normalize_parallel_name_role
          # For parallel names, all should have the same roles.
          name_nodes = ng_xml.root.xpath('//mods:name[@altRepGroup]', mods: ModsNormalizer::MODS_NS)
          grouped_name_nodes = name_nodes.group_by { |name_node| name_node['altRepGroup'] }.values.reject { |name_node_group| name_node_group.size == 1 }
          grouped_name_nodes.each do |name_node_group|
            name_node_with_role = name_node_group.find { |name_node| role_node_for(name_node) }
            next unless name_node_with_role

            name_node_group.each do |name_node|
              next if name_node == name_node_with_role

              existing_role_node = role_node_for(name_node)
              existing_role_node&.remove

              name_node << role_node_for(name_node_with_role).dup
            end
          end
        end

        def role_node_for(name_node)
          name_node.xpath('mods:role', mods: ModsNormalizer::MODS_NS).first
        end

        def normalize_text_role_term
          # Add the type="text" attribute to roleTerms that don't have a type (seen in MODS 3.3 druid:yy910cj7795)
          ng_xml.root.xpath('//mods:roleTerm[not(@type)]', mods: ModsNormalizer::MODS_NS).each do |role_term_node|
            role_term_node['type'] = 'text'
          end
        end

        def normalize_name
          ng_xml.root.xpath('//mods:namePart[not(text())]', mods: ModsNormalizer::MODS_NS).each(&:remove)
          ng_xml.root.xpath('//mods:name[not(mods:namePart) and not(@xlink:href) and not(mods:etal) and not(@valueURI)]',
                            mods: ModsNormalizer::MODS_NS, xlink: ModsNormalizer::XLINK_NS).each(&:remove)

          # Some MODS 3.3 items have xlink:href attributes. See https://argo.stanford.edu/view/druid:yy910cj7795
          # Move them only when there are children.
          ng_xml.xpath('//mods:name[@xlink:href and mods:*]', mods: ModsNormalizer::MODS_NS, xlink: ModsNormalizer::XLINK_NS).each do |node|
            node['valueURI'] = node.remove_attribute('href').value
          end
        end

        def normalize_dupes
          normalize_dupes_for(ng_xml.root)
          ng_xml.root.xpath('mods:relatedItem', mods: ModsNormalizer::MODS_NS).each { |related_item_node| normalize_dupes_for(related_item_node) }
        end

        def normalize_dupes_for(base_node)
          name_nodes = base_node.xpath('mods:name', mods: ModsNormalizer::MODS_NS)

          dupe_name_nodes_groups = name_nodes.group_by { |name_node| name_node_comparitor(name_node) }.values.select { |grouped_name_nodes| grouped_name_nodes.size > 1 }

          dupe_name_nodes_groups.each do |dupe_name_nodes|
            # If there is a name with nameTitleGroup, prefer retaining it.
            nametitle_names, other_names = dupe_name_nodes.partition { |name_node| name_node['nameTitleGroup'] }
            ordered_name_nodes = nametitle_names + other_names

            uniq_name_nodes = ordered_name_nodes.uniq { |name_node| name_node_comparitor(name_node) }
            include_all_uniq_roles(uniq_name_nodes, base_node)

            ordered_name_nodes[1..].each(&:remove)
          end
        end

        def name_node_comparitor(name_node)
          dup_name_node = name_node.dup
          dup_name_node.delete('usage')
          dup_name_node.delete('nameTitleGroup')
          dup_name_node.xpath('mods:role', mods: 'http://www.loc.gov/mods/v3').each(&:unlink)
          dup_name_node.to_s.strip.gsub(/\s+/, ' ')
        end

        # ensure all roles for uniq name node are included
        def include_all_uniq_roles(uniq_name_nodes, base_node)
          uniq_name_nodes.each do |uniq_name_node|
            role_nodes = uniq_name_comparitor_2_role_nodes(base_node)[name_node_comparitor(uniq_name_node)]
            next if role_nodes.blank? || role_nodes.size < 2

            uniq_name_node.xpath('mods:role', mods: 'http://www.loc.gov/mods/v3').each(&:unlink)
            role_nodes.each { |role_node| uniq_name_node.add_child(role_node) }
          end
          uniq_name_nodes
        end

        def uniq_name_comparitor_2_role_nodes(base_node)
          role_nodes = base_node.xpath('mods:name/mods:role', mods: 'http://www.loc.gov/mods/v3')
          # we can use name_node_comparitor to get uniq role nodes
          uniq_role_nodes = role_nodes.uniq { |role_node| name_node_comparitor(role_node) }
          return {} if uniq_role_nodes.size < 2

          result = {}
          uniq_role_nodes.each do |role_node|
            name_comparitor = name_node_comparitor(role_node.parent)
            result[name_comparitor] = if result[name_comparitor]
                                        result[name_comparitor] << role_node
                                      else
                                        [role_node]
                                      end
          end
          result
        end

        def normalize_type
          ng_xml.root.xpath('//mods:name[@type]', mods: ModsNormalizer::MODS_NS).each do |name_node_w_type|
            raw_type = name_node_w_type['type']
            next if FromFedora::Descriptive::Contributor::ROLES.key?(raw_type)

            if FromFedora::Descriptive::Contributor::ROLES.key?(raw_type.downcase)
              name_node_w_type['type'] = raw_type.downcase
            else
              name_node_w_type.remove_attribute('type')
            end
          end
        end

        def normalize_name_part_type
          ng_xml.root.xpath('//mods:namePart[(@type)]', mods: ModsNormalizer::MODS_NS).each do |name_part_node|
            raw_type = name_part_node['type']
            next if FromFedora::Descriptive::Contributor::NAME_PART.key?(raw_type)

            name_part_node.remove_attribute('type')
          end
        end

        # remove the roleTerm when there is no text value and no valueURI or URI attribute
        def normalize_role_term
          ng_xml.root.xpath('//mods:roleTerm[not(text()) and not(@valueURI) and not(@authorityURI)]', mods: ModsNormalizer::MODS_NS).each(&:remove)
        end

        # remove the role when there are no child elements and no attributes
        def normalize_role
          ng_xml.root.xpath('//mods:role[not(mods:*) and not(@*)]', mods: ModsNormalizer::MODS_NS).each(&:remove)
        end
      end
    end
  end
end
