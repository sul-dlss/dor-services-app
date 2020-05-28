# frozen_string_literal: true

# Functions for querying MODS XML
class ModsUtils
  # @param [Nokogiri::Document] ng_xml
  # @return [Nokogiri::Element]
  def self.primary_title_info(ng_xml)
    title_info = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]', mods: Dor::DescMetadataDS::MODS_NS).first
    title_info ||= ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]', mods: Dor::DescMetadataDS::MODS_NS).first
    title_info ||= ng_xml.xpath('//mods:mods/mods:titleInfo', mods: Dor::DescMetadataDS::MODS_NS).first

    title_info
  end
end
