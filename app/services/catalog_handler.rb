# frozen_string_literal: true

class CatalogHandler
  def fetch(prefix, identifier)
    marcxml = MarcxmlResource.find_by(prefix.to_sym => identifier)
    marcxml.mods
  end

  def label(metadata)
    mods = Nokogiri::XML(metadata)
    mods.root.add_namespace_definition('mods', 'http://www.loc.gov/mods/v3')
    mods.xpath('/mods:mods/mods:titleInfo[1]').xpath('mods:title|mods:nonSort').collect(&:text).join(' ').strip
  end

  def prefixes
    %w[catkey barcode]
  end
end
