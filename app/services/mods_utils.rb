# frozen_string_literal: true

# Functions for querying MODS XML
class ModsUtils
  # @param [Nokogiri::Document] ng_xml
  # @return [Nokogiri::Element]
  def self.primary_title_info(ng_xml)
    title_info = ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).first
    title_info ||= ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NS).first
    title_info ||= ng_xml.xpath('//mods:mods/mods:titleInfo', mods: Cocina::FromFedora::Descriptive::DESC_METADATA_NSS).first

    title_info
  end
end
