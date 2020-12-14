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

    def normalize
      normalize_default_namespace
      normalize_version
      normalize_empty_attributes
      normalize_subject
      normalize_authority_uris
      normalize_origin_info_event_types
      normalize_origin_info_date_other_types
      normalize_origin_info_place_term_type
      normalize_subject_authority
      normalize_subject_authority_lcnaf
      normalize_subject_authority_naf
      normalize_text_role_term
      normalize_role_term_authority
      normalize_name
      normalize_related_item_other_type
      normalize_unmatched_altrepgroup
      normalize_xml_space
      normalize_language_term_type
      normalize_geo_purl
      normalize_dc_image
      normalize_access_condition
      normalize_identifier_type
      normalize_location_physical_location
      normalize_purl
      normalize_empty_notes
      normalize_empty_related_item_parts
      normalize_empty_subtitle
      ng_xml
    end

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
        elsif child_node[:authority] && subject_node[:authority] == child_node[:authority]
          child_node.delete('authority')
        end
      end
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
    end

    def normalize_role_term_authority
      ng_xml.root.xpath("//mods:roleTerm[@authority='marcrelator']", mods: MODS_NS).each do |role_term_node|
        role_term_node['authorityURI'] = 'http://id.loc.gov/vocabulary/relators/'
      end
    end

    def normalize_purl
      location_nodes = ng_xml.root.xpath('//mods:location', mods: MODS_NS)
      any_url_primary_usage = ng_xml.root.xpath('//mods:location/mods:url[@usage="primary display"]', mods: MODS_NS).present?

      location_nodes.each do |location_node|
        location_url_nodes = location_node.xpath('mods:url', mods: MODS_NS)
        location_url_nodes.select { |url_node| Cocina::FromFedora::Descriptive::Location::PURL_REGEX.match(url_node.text) }.each do |purl_node|
          purl_node[:usage] = 'primary display' if !any_url_primary_usage && purl_node.text.ends_with?(druid.delete_prefix('druid:'))
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
      altrepgroups = {}
      ng_xml.root.xpath('//mods:*[@altRepGroup]', mods: MODS_NS).each do |node|
        altrepgroup = node['altRepGroup']
        altrepgroups[altrepgroup] = [] unless altrepgroups.include?(altrepgroup)
        altrepgroups[altrepgroup] << node
      end

      altrepgroups.each do |_altrepgroup, nodes|
        next unless nodes.size == 1

        nodes.first.delete('altRepGroup')
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

    def normalize_empty_related_item_parts
      ng_xml.root.xpath('//mods:relatedItem/mods:part[count(mods:*)=1]/mods:detail[count(mods:*)=1]/mods:number[not(text())]', mods: MODS_NS).each do |number_node|
        number_node.parent.parent.remove
      end
    end

    def normalize_name
      ng_xml.root.xpath('//mods:namePart[not(text())]', mods: MODS_NS).each(&:remove)
      ng_xml.root.xpath('//mods:name[not(mods:namePart)]', mods: MODS_NS).each(&:remove)
    end

    def normalize_empty_subtitle
      ng_xml.root.xpath('//mods:subTitle[not(text())]', mods: MODS_NS).each(&:remove)
    end
  end
end
