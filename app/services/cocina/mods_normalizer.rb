# frozen_string_literal: true

module Cocina
  # Normalizes a Fedora MODS document, accounting for differences between Fedora MODS and MODS generated from Cocina.
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
    def normalize
      normalize_default_namespace
      normalize_version
      normalize_empty_attributes
      normalize_subject
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
      normalize_subject_authority
      normalize_subject_authority_lcnaf
      normalize_subject_authority_naf
      normalize_subject_authority_tgm
      normalize_coordinates # Must be before normalize_subject_cartographics
      normalize_subject_cartographics
      normalize_text_role_term
      normalize_role_term_authority
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
      normalize_abstract_summary
      # This should be last-ish.
      normalize_empty_related_items
      ng_xml
    end
    # rubocop:enable Metrics/AbcSize

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

      ng_xml.root['version'] = '3.6'
      ng_xml.root['xsi:schemaLocation'] = 'http://www.loc.gov/mods/v3 http://www.loc.gov/standards/mods/v3/mods-3-6.xsd'
    end

    def normalize_authority_uris
      Cocina::FromFedora::Descriptive::Authority::NORMALIZE_AUTHORITY_URIS.each do |authority_uri|
        ng_xml.root.xpath("//mods:*[@authorityURI='#{authority_uri}']", mods: MODS_NS).each do |node|
          node[:authorityURI] = "#{authority_uri}/"
        end
      end
    end

    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    # rubocop:disable Metrics/AbcSize
    def normalize_subject
      ng_xml.root.xpath('//mods:subject[count(mods:name|mods:topic|mods:geographic) = 1 and count(mods:*) = 1]', mods: MODS_NS).each do |subject_node|
        child_node = subject_node.xpath('mods:*', mods: MODS_NS).first

        if subject_node[:authorityURI] || subject_node[:valueURI]
          # If subject has authority and child doesn't, copy to child.
          child_node[:authority] = subject_node[:authority] if subject_node[:authority] && !child_node[:authority]
          # If subject has authorityURI and child doesn't, move to child.
          child_node[:authorityURI] = subject_node[:authorityURI] if subject_node[:authorityURI] && !child_node[:authorityURI]
          subject_node.delete('authorityURI')
          # If subject has valueURI and child doesn't, move to child.
          child_node[:valueURI] = subject_node[:valueURI] if subject_node[:valueURI] && !child_node[:valueURI]
          subject_node.delete('valueURI')
        elsif child_node[:authority] && subject_node[:authority] == child_node[:authority] && !(child_node[:authorityURI] || child_node[:valueURI])
          child_node.delete('authority')
        elsif subject_node[:authority] && !child_node[:authority] && (child_node[:authorityURI] || child_node[:valueURI])
          child_node[:authority] = subject_node[:authority]
        end
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
    # rubocop:enable Metrics/AbcSize

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
        date_issued_nodes = origin_info_node.xpath('mods:dateIssued', mods: MODS_NS)
        add_event_type('publication', origin_info_node) && next if date_issued_nodes.present?

        copyright_date_nodes = origin_info_node.xpath('mods:copyrightDate', mods: MODS_NS)
        add_event_type('copyright notice', origin_info_node) && next if copyright_date_nodes.present?

        date_created_nodes = origin_info_node.xpath('mods:dateCreated', mods: MODS_NS)
        add_event_type('production', origin_info_node) && next if date_created_nodes.present?

        date_captured_nodes = origin_info_node.xpath('mods:dateCaptured', mods: MODS_NS)
        add_event_type('capture', origin_info_node) && next if date_captured_nodes.present?

        date_valid_nodes = origin_info_node.xpath('mods:dateValid', mods: MODS_NS)
        add_event_type('validity', origin_info_node) && next if date_valid_nodes.present?

        publisher = origin_info_node.xpath('mods:publisher', mods: MODS_NS)
        add_event_type('publication', origin_info_node) && next if publisher.present?

        edition = origin_info_node.xpath('mods:edition', mods: MODS_NS)
        add_event_type('publication', origin_info_node) && next if edition.present?

        issuance = origin_info_node.xpath('mods:issuance', mods: MODS_NS)
        add_event_type('publication', origin_info_node) && next if issuance.present?

        frequency = origin_info_node.xpath('mods:frequency', mods: MODS_NS)
        add_event_type('publication', origin_info_node) && next if frequency.present?
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity

    def add_event_type(value, origin_info_node)
      origin_info_node['eventType'] = value if origin_info_node[:eventType].blank?
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

    def normalize_role_term_authority
      ng_xml.root.xpath("//mods:roleTerm[@authority='marcrelator']", mods: MODS_NS).each do |role_term_node|
        role_term_node['authorityURI'] = 'http://id.loc.gov/vocabulary/relators/'
      end
    end

    def normalize_purl
      normalize_purl_for(ng_xml.root, true)
      ng_xml.root.xpath('mods:relatedItem', mods: MODS_NS).each { |related_item_node| normalize_purl_for(related_item_node, false) }
    end

    def normalize_purl_for(base_node, match_purl)
      location_nodes = base_node.xpath('mods:location', mods: MODS_NS)
      any_url_primary_usage = base_node.xpath('mods:location/mods:url[@usage="primary display"]', mods: MODS_NS).present?

      location_nodes.each do |location_node|
        location_url_nodes = location_node.xpath('mods:url', mods: MODS_NS)
        location_url_nodes.select { |url_node| Cocina::FromFedora::Descriptive::Access::PURL_REGEX.match(url_node.text) }.each do |purl_node|
          purl_node[:usage] = 'primary display' if !any_url_primary_usage && (!match_purl || purl_node.text.ends_with?(druid.delete_prefix('druid:')))
          purl_node.delete('displayLabel') if purl_node[:displayLabel] == 'electronic resource' && purl_node[:usage] == 'primary display'
        end
      end
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
              .to_a
              .filter { |date_node| date_node.content =~ /^\d{4}\.$/ }
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
      split_origin_info('dateIssued', 'copyrightDate', 'copyright notice')
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
