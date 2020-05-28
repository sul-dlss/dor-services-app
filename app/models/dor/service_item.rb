# frozen_string_literal: true

module Dor
  class ServiceItem
    def initialize(druid_obj)
      @druid_obj = druid_obj
    end

    private

    def primary_mods_title_info_element
      return nil unless @druid_obj.datastreams['descMetadata']

      title_info = @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.descMetadata.ng_xml.xpath('//mods:mods/mods:titleInfo', mods: 'http://www.loc.gov/mods/v3').first

      title_info
    end
  end
end
