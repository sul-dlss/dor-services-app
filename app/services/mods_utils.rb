# frozen_string_literal: true

# Functions for querying MODS XML
class ModsUtils
  def self.label(ng_xml)
    ng_xml.root.add_namespace_definition('mods', 'http://www.loc.gov/mods/v3')
    ng_xml.xpath('/mods:mods/mods:titleInfo[1]')
          .xpath('mods:title|mods:nonSort')
          .collect(&:text).join(' ').strip
  end
end
