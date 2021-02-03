# frozen_string_literal: true

module Cocina
  # Normalizes a Fedora MODS document, accounting for differences between Fedora MODS and MODS generated from Cocina.
  # these adjustments have been approved by our metadata authority, Arcadia.
  class ModsNormalizer
    MODS_NS = Cocina::FromFedora::Descriptive::DESC_METADATA_NS

    # @param [Nokogiri::Document] mods_ng_xml MODS to be normalized
    # @param [String] druid
    # @return [Nokogiri::Document] normalized MODS
    def self.normalize(mods_ng_xml:, druid:)
      ModsNormalizer.new(mods_ng_xml: mods_ng_xml, druid: druid).normalize
    end

    def initialize(mods_ng_xml:, druid:)
      @ng_xml = mods_ng_xml.dup
      @druid = druid
    end

    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/MethodLength
    def normalize
      normalize_default_namespace
      normalize_version
      normalize_empty_attributes
      normalize_authority_uris
      normalize_origin_info_split
      normalize_origin_info_event_types
      normalize_origin_info_date_other_types
      normalize_origin_info_place_term_type
      normalize_origin_info_developed_date
      normalize_origin_info_date
      normalize_origin_info_publisher
      normalize_parallel_origin_info
      normalize_origin_info_lang_script
      normalize_subject
      normalize_subject_children
      normalize_subject_authority
      normalize_subject_authority_lcnaf
      normalize_subject_authority_naf
      normalize_subject_authority_tgm
      normalize_coordinates # Must be before normalize_subject_cartographics
      normalize_subject_cartographics
      normalize_text_role_term
      normalize_name
      normalize_related_item_other_type
      normalize_unmatched_altrepgroup
      normalize_unmatched_nametitlegroup
      normalize_xml_space
      normalize_language_term_type
      normalize_geo_purl
      normalize_dc_image
      normalize_access_condition
      normalize_identifier_type
      normalize_location_physical_location
      normalize_purl
      normalize_empty_notes
      normalize_empty_titles
      normalize_title_type
      normalize_title_trailing
      normalize_gml_id
      normalize_empty_resource
      normalize_empty_type_of_resource # Must be after normalize_empty_attributes
      normalize_abstract_summary
      # This should be last-ish.
      normalize_empty_related_items
      ng_xml
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength

    private

    attr_reader :ng_xml, :druid

    def normalize_default_namespace
      xml = ng_xml.to_s

      unless xml.include?('xmlns="http://www.loc.gov/mods/v3"')
        xml.sub!('mods:mods', 'mods:mods xmlns="http://www.loc.gov/mods/v3"')
        xml.gsub!('mods:', '')
      end
      @ng_xml = Nokogiri::XML(xml) { |config| config.default_xml.noblanks }
    end

    def normalize_version
      # Only normalize version when version isn't mapped.
      return if /MODS version (\d\.\d)/.match(ng_xml.root.at('//mods:recordInfo/mods:recordOrigin', mods: MODS_NS)&.content)

      ng_xml.root['version'] = '3.7'
      ng_xml.root['xsi:schemaLocation'] = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-7.xsd'
    end

    def normalize_authority_uris
      Cocina::FromFedora::Descriptive::Authority::NORMALIZE_AUTHORITY_URIS.each do |authority_uri|
        ng_xml.root.xpath("//mods:*[@authorityURI='#{authority_uri}']", mods: MODS_NS).each do |node|
          node[:authorityURI] = "#{authority_uri}/"
        end
      end
    end

    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/CyclomaticComplexity
    def normalize_subject
      ng_xml.root.xpath('//mods:subject[not(mods:cartographics)]', mods: MODS_NS).each do |subject_node|
        children_nodes = subject_node.xpath('mods:*', mods: MODS_NS)

        if (have_authorityURI?(subject_node) || have_valueURI?(subject_node)) \
          && children_nodes.size == 1
          # If subject has authority and child doesn't, copy to child.
          add_authority(children_nodes, subject_node) if have_authority?(subject_node) && !have_authority?(children_nodes)
          # If subject has authorityURI and child doesn't, move to child.
          add_authorityURI(children_nodes, subject_node) if have_authorityURI?(subject_node) && !have_authorityURI?(children_nodes)
          subject_node.delete('authorityURI')
          # If subject has valueURI and child doesn't, move to child.
          add_valueURI(children_nodes, subject_node) if have_valueURI?(subject_node) && !have_valueURI?(children_nodes)
          subject_node.delete('valueURI')
        end

        next unless have_authority?(subject_node) &&
                    have_authorityURI?(subject_node) &&
                    !have_valueURI?(subject_node)

        have_authority?(children_nodes.first) &&
          have_same_authority?(children_nodes, children_nodes.first)

        delete_authorityURI(subject_node)
      end
    end

    def normalize_subject_children
      ng_xml.root.xpath('//mods:subject[not(mods:cartographics)]', mods: MODS_NS).each do |subject_node|
        children_nodes = subject_node.xpath('mods:*', mods: MODS_NS)

        if !have_authorityURI?(subject_node) &&
           !have_valueURI?(subject_node) &&
           have_authority?(children_nodes) &&
           have_same_authority?(children_nodes, subject_node) &&
           !(have_authorityURI?(children_nodes) || have_valueURI?(children_nodes))
          delete_authority(children_nodes)
        end

        next unless !have_authorityURI?(subject_node) &&
                    !have_valueURI?(subject_node) &&
                    have_authority?(subject_node) &&
                    !have_authority?(children_nodes) &&
                    (have_authorityURI?(children_nodes) || have_valueURI?(children_nodes))

        add_authority(children_nodes, subject_node)
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/CyclomaticComplexity

    def have_authority?(nodes)
      nodes_to_a(nodes).all? { |node| node[:authority] }
    end

    def have_same_authority?(nodes, same_node)
      nodes_to_a(nodes).all? { |node| same_node[:authority] == node[:authority] || (lcsh_or_naf?(same_node) && lcsh_or_naf?(node)) }
    end

    def lcsh_or_naf?(node)
      %w[lcsh naf].include?(node[:authority])
    end

    def add_authority(nodes, from_node)
      nodes_to_a(nodes).each { |node| node[:authority] = from_node[:authority] }
    end

    def delete_authority(nodes)
      nodes_to_a(nodes).each { |node| node.delete('authority') }
    end

    # rubocop:disable Naming/MethodName
    def have_authorityURI?(nodes)
      nodes_to_a(nodes).all? { |node| node[:authorityURI] }
    end

    def add_authorityURI(nodes, from_node)
      nodes_to_a(nodes).each { |node| node[:authorityURI] = from_node[:authorityURI] }
    end

    def delete_authorityURI(nodes)
      nodes_to_a(nodes).each { |node| node.delete('authorityURI') }
    end

    def have_valueURI?(nodes)
      nodes_to_a(nodes).all? { |node| node[:valueURI] }
    end

    def add_valueURI(nodes, from_node)
      nodes_to_a(nodes).each { |node| node[:valueURI] = from_node[:valueURI] }
    end
    # rubocop:enable Naming/MethodName

    def nodes_to_a(nodes)
      nodes.is_a?(Nokogiri::XML::NodeSet) ? nodes : [nodes]
    end

    def normalize_coordinates
      ng_xml.root.xpath('//mods:coordinates[text()]', mods: MODS_NS).each do |coordinate_node|
        coordinate_node.content = coordinate_node.content.delete_prefix('(').delete_suffix(')')
      end
    end

    # Collapse multiple subject/cartographics nodes into a single one
    def normalize_subject_cartographics
      normalize_subject_cartographics_for(ng_xml.root)
      ng_xml.root.xpath('mods:relatedItem', mods: MODS_NS).each { |related_item_node| normalize_subject_cartographics_for(related_item_node) }
    end

    def normalize_subject_cartographics_for(root_node)
      carto_subject_nodes = root_node.xpath('mods:subject[mods:cartographics]', mods: MODS_NS)
      return if carto_subject_nodes.empty?

      # Create a default carto subject.
      default_carto_subject_node = Nokogiri::XML::Node.new('subject', Nokogiri::XML(nil))
      default_carto_node = Nokogiri::XML::Node.new('cartographics', Nokogiri::XML(nil))
      default_carto_subject_node << default_carto_node

      carto_subject_nodes.each do |carto_subject_node|
        carto_subject_node.xpath('mods:cartographics', mods: MODS_NS).each do |carto_node|
          normalize_cartographic_node(carto_node, carto_subject_node, default_carto_node)
        end
        carto_subject_node.remove if carto_subject_node.elements.empty?
      end

      root_node << default_carto_subject_node if default_carto_node.elements.present?
    end

    # Normalizes a single cartographic node
    def normalize_cartographic_node(carto_node, carto_subject_node, default_carto_node)
      child_nodes = if carto_subject_node['authority'] || carto_subject_node['authorityURI'] || carto_subject_node['valueURI']
                      # Move scale and coordinates to default carto subject.
                      carto_node.xpath('mods:scale', mods: MODS_NS) + carto_node.xpath('mods:coordinates', mods: MODS_NS)
                    else
                      # Merge all into default carto_subject.
                      carto_node.elements
                    end

      child_nodes.each do |child_node|
        child_node.remove
        next if child_node.children.blank? # skip empty nodes

        default_carto_node << child_node unless child_node_exists?(child_node, default_carto_node)
      end
      carto_node.remove if carto_node.elements.empty?
    end

    def child_node_exists?(child_node, parent_node)
      parent_node.elements.any? { |check_node| child_node.name == check_node.name && child_node.content == check_node.content }
    end

    def normalize_subject_authority_naf
      ng_xml.root.xpath("//mods:subject[@authority='naf']", mods: MODS_NS).each do |subject_node|
        subject_node[:authority] = 'lcsh'
      end
    end

    # change original xml to have the event type that will be output
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def normalize_origin_info_event_types
      ng_xml.root.xpath('//mods:originInfo', mods: MODS_NS).each do |origin_info_node|
        next if normalize_event_type(origin_info_node, 'dateIssued', 'publication', ->(oi_node) { oi_node['eventType'] != 'presentation' })

        copyright_date_nodes = origin_info_node.xpath('mods:copyrightDate', mods: MODS_NS)
        if copyright_date_nodes.present?
          origin_info_node['eventType'] = 'copyright' if origin_info_node['eventType'] != 'copyright notice'
          next
        end

        next if normalize_event_type(origin_info_node, 'dateCreated', 'production')
        next if normalize_event_type(origin_info_node, 'dateCaptured', 'capture')
        next if normalize_event_type(origin_info_node, 'dateValid', 'validity')
        next if normalize_date_other_event_type(origin_info_node)

        event_type_nil_lambda = ->(oi_node) { oi_node['eventType'].nil? }

        next if normalize_event_type(origin_info_node, 'publisher', 'publication', event_type_nil_lambda)
        next if normalize_event_type(origin_info_node, 'edition', 'publication', event_type_nil_lambda)
        next if normalize_event_type(origin_info_node, 'issuance', 'publication', event_type_nil_lambda)
        next if normalize_event_type(origin_info_node, 'frequency', 'publication', event_type_nil_lambda)
        next if normalize_event_type(origin_info_node, 'place', 'publication', event_type_nil_lambda)
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def normalize_date_other_event_type(origin_info_node)
      date_other_node = origin_info_node.xpath('mods:dateOther[@type]', mods: MODS_NS).first
      return false unless date_other_node.present? && Cocina::ToFedora::Descriptive::Event::DATE_OTHER_TYPE.keys.include?(date_other_node['type']) && origin_info_node['eventType'].nil?

      origin_info_node['eventType'] = date_other_node['type']
      true
    end

    def normalize_event_type(origin_info_node, child_node_name, event_type, filter = nil)
      child_nodes = origin_info_node.xpath("mods:#{child_node_name}", mods: MODS_NS)
      return false if child_nodes.blank?
      return false if filter && !filter.call(origin_info_node)

      origin_info_node['eventType'] = event_type
      true
    end

    # NOTE: must be run after normalize_origin_info_event_types
    # remove dateOther type attribute if it matches originInfo@eventType and if dateOther is empty
    def normalize_origin_info_date_other_types
      ng_xml.root.xpath('//mods:originInfo[@eventType]', mods: MODS_NS).each do |origin_info_node|
        origin_info_event_type = origin_info_node['eventType']
        origin_info_node.xpath('mods:dateOther[@type]', mods: MODS_NS).each do |date_other_node|
          next if date_other_node.content.present?

          date_other_node.remove_attribute('type') if origin_info_event_type.match?(date_other_node['type'])
        end
      end
    end

    # if the cocina model doesn't have a code, then it will have a value;
    #   this is output as attribute type=text on the roundtripped placeTerm element
    def normalize_origin_info_place_term_type
      ng_xml.root.xpath('//mods:originInfo/mods:place/mods:placeTerm', mods: MODS_NS).each do |place_term_node|
        next if place_term_node.content.blank?

        place_term_node['type'] = 'text' if place_term_node.attributes['type'].blank?
      end
    end

    def normalize_text_role_term
      ng_xml.root.xpath("//mods:roleTerm[@type='text']", mods: MODS_NS).each do |role_term_node|
        role_term_node.content = role_term_node.content.downcase
      end

      # Add the type="text" attribute to roleTerms that don't have a type (seen in MODS 3.3 druid:yy910cj7795)
      ng_xml.root.xpath('//mods:roleTerm[not(@type)]', mods: MODS_NS).each do |role_term_node|
        role_term_node['type'] = 'text'
      end
    end

    def normalize_purl
      normalize_purl_for(ng_xml.root, true)
      ng_xml.root.xpath('mods:relatedItem', mods: MODS_NS).each { |related_item_node| normalize_purl_for(related_item_node, false) }
    end

    def normalize_purl_for(base_node, match_purl)
      url_nodes, purl_nodes = partition_url_nodes(base_node)

      any_purl_primary_usage = any_purl_primary_usage?(base_node)
      purl_nodes.each do |purl_node|
        if !any_purl_primary_usage && (!match_purl || purl_node.text.ends_with?(druid.delete_prefix('druid:')))
          purl_node[:usage] = 'primary display'
          any_purl_primary_usage = true
        end
        purl_node.delete('displayLabel') if purl_node[:displayLabel] == 'electronic resource' && purl_node[:usage] == 'primary display'
      end

      url_nodes.each do |url_node|
        url_node.delete('usage') if url_node[:usage] == 'primary display' && any_purl_primary_usage
      end
    end

    def partition_url_nodes(base_node)
      purl_nodes = []
      url_nodes = []
      base_node.xpath('mods:location', mods: MODS_NS).each do |location_node|
        location_node.xpath('mods:url', mods: MODS_NS).each do |url_node|
          if purl?(url_node)
            purl_nodes << url_node
          else
            url_nodes << url_node
          end
        end
      end
      [url_nodes, purl_nodes]
    end

    def any_purl_primary_usage?(base_node)
      base_node.xpath('mods:location/mods:url[@usage="primary display"]', mods: MODS_NS).any? { |url_node| purl?(url_node) }
    end

    def purl?(url_node)
      Cocina::FromFedora::Descriptive::Access::PURL_REGEX.match(url_node.text)
    end

    def normalize_related_item_other_type
      ng_xml.root.xpath('//mods:relatedItem[@type and @otherType]', mods: MODS_NS).each do |related_node|
        related_node.delete('otherType')
        related_node.delete('otherTypeURI')
        related_node.delete('otherTypeAuth')
      end
    end

    def normalize_empty_notes
      ng_xml.root.xpath('//mods:note[not(text())]', mods: MODS_NS).each(&:remove)
    end

    def normalize_empty_type_of_resource
      ng_xml.root.xpath('//mods:typeOfResource[not(text())][not(@*)]', mods: MODS_NS).each(&:remove)
    end

    def normalize_unmatched_altrepgroup
      remove_unmatched('altRepGroup')
    end

    def normalize_unmatched_nametitlegroup
      remove_unmatched('nameTitleGroup')
    end

    def remove_unmatched(attr_name)
      ids = {}
      ng_xml.root.xpath("//mods:*[@#{attr_name}]", mods: MODS_NS).each do |node|
        id = node[attr_name]
        ids[id] ||= []
        ids[id] << node
      end

      ids.each_value do |nodes|
        next unless nodes.size == 1

        nodes.first.delete(attr_name)
      end
    end

    def normalize_empty_attributes
      ng_xml.root.xpath('//mods:*[@*=""]', mods: MODS_NS).each do |node|
        node.each { |attr_name, attr_value| node.delete(attr_name) if attr_value.blank? }
      end
    end

    def normalize_xml_space
      ng_xml.root.xpath('//mods:*[@xml:space]', mods: MODS_NS).each do |node|
        node.delete('space')
      end
    end

    def normalize_language_term_type
      ng_xml.root.xpath('//mods:languageTerm[not(@type)]', mods: MODS_NS).each do |node|
        node['type'] = 'code'
      end
    end

    def normalize_subject_authority
      ng_xml.root.xpath('//mods:subject[not(@authority) and count(mods:*) = 1 and not(mods:geographicCode)]/mods:*[@authority]',
                        mods: MODS_NS).each do |node|
        node.parent['authority'] = node['authority']
        node.delete('authority') unless node['authorityURI'] || node['valueURI']
      end
    end

    def normalize_geo_purl
      ng_xml.root.xpath('//mods:extension[@displayLabel="geo"]//rdf:Description',
                        mods: MODS_NS,
                        rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').each do |node|
        node['rdf:about'] = "http://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
      end
    end

    def normalize_dc_image
      ng_xml.root.xpath('//mods:extension[@displayLabel="geo"]//dc:type[text() = "image"]',
                        mods: MODS_NS,
                        dc: 'http://purl.org/dc/elements/1.1/').each do |node|
        node.content = 'Image'
      end
    end

    def normalize_access_condition
      ng_xml.root.xpath('//mods:accessCondition[@type="restrictionOnAccess"]', mods: MODS_NS).each do |node|
        node['type'] = 'restriction on access'
      end
      ng_xml.root.xpath('//mods:accessCondition[@type="useAndReproduction"]', mods: MODS_NS).each do |node|
        node['type'] = 'use and reproduction'
      end
    end

    def normalize_identifier_type
      ng_xml.root.xpath('//mods:identifier[@type]', mods: MODS_NS).each do |node|
        node['type'] = normalized_identifier_type_for(node['type'])
      end
      ng_xml.root.xpath('//mods:nameIdentifier[@type]', mods: MODS_NS).each do |node|
        node['type'] = normalized_identifier_type_for(node['type'])
      end
      ng_xml.root.xpath('//mods:recordIdentifier[@source]', mods: MODS_NS).each do |node|
        node['source'] = normalized_identifier_type_for(node['source'])
      end
    end

    def normalized_identifier_type_for(type)
      cocina_type, _mods_type, identifier_source = Cocina::FromFedora::Descriptive::IdentifierType.cocina_type_for_mods_type(type)

      return Cocina::FromFedora::Descriptive::IdentifierType.mods_type_for_cocina_type(cocina_type) if identifier_source

      type
    end

    def normalize_subject_authority_lcnaf
      ng_xml.root.xpath("//mods:*[@authority='lcnaf']", mods: MODS_NS).each do |node|
        node[:authority] = 'naf'
      end
    end

    def normalize_subject_authority_tgm
      ng_xml.root.xpath("//mods:*[@authority='tgm']", mods: MODS_NS).each do |node|
        node[:authority] = 'lctgm'
      end
    end

    def normalize_location_physical_location
      ng_xml.root.xpath('//mods:location', mods: MODS_NS).each do |location_node|
        location_node.xpath('mods:physicalLocation|mods:url|mods:shelfLocator', mods: MODS_NS).each do |node|
          new_location = Nokogiri::XML::Node.new('location', Nokogiri::XML(nil))
          new_location << node
          location_node.parent << new_location
        end
        location_node.remove
      end
    end

    def normalize_empty_related_items
      ng_xml.root.xpath('//mods:relatedItem/mods:part[count(mods:*)=1]/mods:detail[count(mods:*)=1]/mods:number[not(text())]', mods: MODS_NS).each do |number_node|
        number_node.parent.parent.remove
      end
      ng_xml.root.xpath('//mods:relatedItem[not(mods:*)]', mods: MODS_NS).each(&:remove)
    end

    def normalize_name
      ng_xml.root.xpath('//mods:namePart[not(text())]', mods: MODS_NS).each(&:remove)
      ng_xml.root.xpath('//mods:name[not(mods:namePart)]', mods: MODS_NS).each(&:remove)

      # Some MODS 3.3 items have xlink:href attributes. See https://argo.stanford.edu/view/druid:yy910cj7795
      ng_xml.xpath('//mods:name[@xlink:href]', mods: MODS_NS, xlink: 'http://www.w3.org/1999/xlink').each do |node|
        node['valueURI'] = node.remove_attribute('href').value
      end
    end

    def normalize_empty_titles
      ng_xml.root.xpath('//mods:title[not(text())]', mods: MODS_NS).each(&:remove)
      ng_xml.root.xpath('//mods:subTitle[not(text())]', mods: MODS_NS).each(&:remove)
      ng_xml.root.xpath('//mods:titleInfo[not(mods:*)]', mods: MODS_NS).each(&:remove)
    end

    def normalize_origin_info_developed_date
      ng_xml.root.xpath('//mods:originInfo/mods:dateOther[@type="developed"]', mods: MODS_NS).each do |date_other|
        # Move to own originInfo
        new_origin_info = Nokogiri::XML::Node.new('originInfo', Nokogiri::XML(nil))
        new_origin_info[:eventType] = 'development'
        new_origin_info << date_other.dup
        date_other.parent.parent << new_origin_info
        date_other.remove
      end
    end

    def normalize_origin_info_date
      %w[dateIssued copyrightDate dateCreated dateCaptured dateValid dateOther].each do |date_type|
        ng_xml.root.xpath("//mods:originInfo/mods:#{date_type}", mods: MODS_NS)
              .each { |date_node| date_node.content = date_node.content.delete_suffix('.') }
      end
    end

    def normalize_parallel_origin_info
      # For grouped originInfos, if no lang or script or lang and script are the same then make sure other values present on all in group.
      altrepgroup_origin_info_nodes, _other_origin_info_nodes = Cocina::FromFedora::Descriptive::AltRepGroup.split(nodes: ng_xml.root.xpath('//mods:originInfo', mods: MODS_NS))

      altrepgroup_origin_info_nodes.each do |origin_info_nodes|
        lang_script_map = origin_info_nodes.group_by { |origin_info_node| [origin_info_node['lang'], origin_info_node['script']] }
        grouped_origin_info_nodes = lang_script_map.values.select { |nodes| nodes.size > 1 }
        grouped_origin_info_nodes.each do |origin_info_node_group|
          origin_info_node_group.each do |origin_info_node|
            other_origin_info_nodes = origin_info_node_group.reject { |check_origin_info_node| origin_info_node == check_origin_info_node }
            normalize_parallel_origin_info_nodes(origin_info_node, other_origin_info_nodes)
          end
        end
      end
    end

    def normalize_parallel_origin_info_nodes(from_node, to_nodes)
      from_node.elements.each do |child_node|
        to_nodes.each do |to_node|
          next if matching_origin_info_child_node?(child_node, to_node)

          to_node << child_node.dup
        end
      end
    end

    def matching_origin_info_child_node?(child_node, origin_info_node)
      origin_info_node.elements.any? do |other_child_node|
        if child_node.name == 'place' && other_child_node.name == 'place'
          child_placeterm_node = child_node.xpath('mods:placeTerm', mods: MODS_NS).first
          other_child_placeterm_node = other_child_node.xpath('mods:placeTerm', mods: MODS_NS).first
          child_placeterm_node && other_child_placeterm_node && child_placeterm_node['type'] == other_child_placeterm_node['type']
        else
          child_node.name == other_child_node.name && child_node.to_h == other_child_node.to_h
        end
      end
    end

    def normalize_origin_info_lang_script
      # Remove lang and script attributes if none of the children can be parallel.
      ng_xml.root.xpath('//mods:originInfo[@lang or @script]', mods: MODS_NS).each do |origin_info_node|
        parallel_nodes = origin_info_node.xpath('mods:place/mods:placeTerm[not(@type="code")]', mods: MODS_NS) \
          + origin_info_node.xpath('mods:dateIssued[not(@encoding)]', mods: MODS_NS) \
          + origin_info_node.xpath('mods:publisher', mods: MODS_NS) \
          + origin_info_node.xpath('mods:edition', mods: MODS_NS)
        if parallel_nodes.empty?
          origin_info_node.delete('lang')
          origin_info_node.delete('script')
        end
      end
    end

    def normalize_origin_info_split
      # Split a single originInfo into multiple.
      split_origin_info('dateIssued', 'copyrightDate', 'copyright')
      split_origin_info('dateIssued', 'dateCaptured', 'capture')
      split_origin_info('dateIssued', 'dateValid', 'validity')
      split_origin_info('copyrightDate', 'publisher', 'publication')
    end

    def split_origin_info(split_node_name1, split_node_name2, event_type)
      ng_xml.root.xpath("//mods:originInfo[mods:#{split_node_name1} and mods:#{split_node_name2}]", mods: MODS_NS).each do |origin_info_node|
        new_origin_info_node = Nokogiri::XML::Node.new('originInfo', Nokogiri::XML(nil))
        new_origin_info_node['eventType'] = event_type
        origin_info_node.parent << new_origin_info_node
        split_nodes = origin_info_node.xpath("mods:#{split_node_name2}", mods: MODS_NS)
        split_nodes.each do |split_node|
          split_node.remove
          new_origin_info_node << split_node
        end
      end
    end

    def normalize_gml_id
      ng_xml.root.xpath("//gml:Point[@gml:id='ID']", gml: 'http://www.opengis.net/gml/3.2/').each do |point_node|
        point_node.delete('id')
      end
    end

    def normalize_title_type
      ng_xml.root.xpath('//mods:title[@type]', mods: MODS_NS).each do |title_node|
        title_node.delete('type')
      end
    end

    def normalize_empty_resource
      ng_xml.root.xpath('//dc:coverage[@rdf:resource = ""]',
                        dc: 'http://purl.org/dc/elements/1.1/',
                        rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').each do |coverage_node|
        coverage_node.delete('resource')
      end
    end

    def normalize_origin_info_publisher
      ng_xml.root.xpath('//mods:publisher[@lang]', mods: MODS_NS).each do |publisher_node|
        publisher_node.parent['lang'] = publisher_node['lang']
        publisher_node.delete('lang')
      end
      ng_xml.root.xpath('//mods:publisher[@script]', mods: MODS_NS).each do |publisher_node|
        publisher_node.parent['script'] = publisher_node['script']
        publisher_node.delete('script')
      end
      ng_xml.root.xpath('//mods:publisher[@transliteration]', mods: MODS_NS).each do |publisher_node|
        publisher_node.parent['transliteration'] = publisher_node['transliteration']
        publisher_node.delete('transliteration')
      end
    end

    def normalize_abstract_summary
      ng_xml.root.xpath('//mods:abstract[@type="summary"]', mods: MODS_NS).each do |abstract_node|
        abstract_node.delete('type')
      end
    end

    def normalize_title_trailing
      ng_xml.root.xpath('//mods:titleInfo[not(@type="abbreviated")]/mods:title', mods: MODS_NS).each do |title_node|
        title_node.content = title_node.content.delete_suffix(',').delete_suffix('.')
      end
    end
  end
end
