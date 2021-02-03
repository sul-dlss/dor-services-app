# frozen_string_literal: true

module Cocina
  # Normalizes a Fedora MODS document, accounting for differences between Fedora MODS and MODS generated from Cocina.
  # these adjustments have been approved by our metadata authority, Arcadia.
  class ModsNormalizer
    MODS_NS = Cocina::FromFedora::Descriptive::DESC_METADATA_NS
    XLINK_NS = 'http://www.w3.org/1999/xlink'

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
      normalize_authority_uris
      @ng_xml = ModsNormalizers::OriginInfoNormalizer.normalize(mods_ng_xml: ng_xml)
      @ng_xml = ModsNormalizers::SubjectNormalizer.normalize(mods_ng_xml: ng_xml)
      @ng_xml = ModsNormalizers::NameNormalizer.normalize(mods_ng_xml: ng_xml)
      normalize_related_item_other_type
      normalize_unmatched_altrepgroup
      normalize_unmatched_nametitlegroup
      normalize_xml_space
      normalize_language_term_type
      normalize_access_condition
      normalize_identifier_type
      normalize_location_physical_location
      normalize_purl
      normalize_empty_notes
      @ng_xml = ModsNormalizers::TitleNormalizer.normalize(mods_ng_xml: ng_xml)
      @ng_xml = ModsNormalizers::GeoExtensionNormalizer.normalize(mods_ng_xml: ng_xml, druid: druid)
      normalize_empty_type_of_resource # Must be after normalize_empty_attributes
      normalize_abstract_summary
      # This should be last-ish.
      normalize_empty_related_items
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
      ng_xml.root.xpath('//mods:note[not(text()) and not(@xlink:href)]', mods: MODS_NS, xlink: XLINK_NS).each(&:remove)
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

    def normalize_abstract_summary
      ng_xml.root.xpath('//mods:abstract[@type="summary"]', mods: MODS_NS).each do |abstract_node|
        abstract_node.delete('type')
      end
    end
  end
end
