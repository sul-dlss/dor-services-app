# frozen_string_literal: true

# Functions for querying MODS XML
class ModsUtils
  # @param [Nokogiri::Document] ng_xml
  # @return [Nokogiri::Element]
  def self.primary_title_info(ng_xml)
    title_info = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]',
                              mods: Cocina::Models::Mapping::FromMods::Description::DESC_METADATA_NS).first
    title_info ||= ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]',
                                mods: Cocina::Models::Mapping::FromMods::Description::DESC_METADATA_NS).first
    title_info ||= ng_xml.xpath('//mods:mods/mods:titleInfo',
                                mods: Cocina::Models::Mapping::FromMods::Description::DESC_METADATA_NSS).first

    title_info
  end

  def self.label(ng_xml)
    ng_xml.root.add_namespace_definition('mods', 'http://www.loc.gov/mods/v3')
    ng_xml.xpath('/mods:mods/mods:titleInfo[1]')
          .xpath('mods:title|mods:nonSort')
          .collect(&:text).join(' ').strip
  end
end
