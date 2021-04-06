# frozen_string_literal: true

module Publish
  # Exports the rightsMetadata XML that is sent to purl.stanford.edu
  class RightsMetadata
    attr_reader :original

    # @param [Nokogiri::XML] original
    def initialize(original)
      @original = original
    end

    Resource = Struct.new(:code, :label)
    # These codes are the only codes accepted by DefaultObjectRightsDS#use_license=
    # so we can't just add to this list without updating that method.
    # https://github.com/sul-dlss/dor-services/blob/main/lib/dor/services/creative_commons_license_service.rb
    # https://github.com/sul-dlss/dor-services/blob/main/lib/dor/services/open_data_license_service.rb
    LICENSE_CODES = {
      Cocina::FromFedora::License::NONE_LICENSE_URI => Resource.new('none', 'no Creative Commons (CC) license'), # Only used in some legacy ETDs.
      'https://creativecommons.org/share-your-work/public-domain/cc0/' => Resource.new('cc0', 'No Rights Reserved'),
      'https://creativecommons.org/licenses/by/3.0/' => Resource.new('by', 'Attribution 3.0 Unported'),
      'https://creativecommons.org/licenses/by-sa/3.0/' => Resource.new('by-sa', 'Attribution Share Alike 3.0 Unported'),
      'https://creativecommons.org/licenses/by-nd/3.0/' => Resource.new('by-nd', 'Attribution No Derivatives 3.0 Unported'),
      'https://creativecommons.org/licenses/by-nc/3.0/' => Resource.new('by-nc', 'Attribution Non-Commercial 3.0 Unported'),
      'https://creativecommons.org/licenses/by-nc-sa/3.0/' => Resource.new('by-nc-sa', 'Attribution Non-Commercial Share Alike 3.0 Unported'),
      'https://creativecommons.org/licenses/by-nc-nd/3.0/' => Resource.new('by-nc-nd', 'Attribution Non-Commercial, No Derivatives 3.0 Unported'),
      'https://creativecommons.org/licenses/by/4.0/' => Resource.new('by', 'Attribution 4.0 International (CC BY 4.0)'),
      'https://creativecommons.org/licenses/by-sa/4.0/' => Resource.new('by-sa', 'Attribution-ShareAlike 4.0 International (CC BY-SA 4.0)'),
      'https://creativecommons.org/licenses/by-nd/4.0/' => Resource.new('by-nd', 'Attribution-NoDerivatives 4.0 International (CC BY-ND 4.0)'),
      'https://creativecommons.org/licenses/by-nc/4.0/' => Resource.new('by-nc', 'Attribution-NonCommercial 4.0 International (CC BY-NC 4.0) '),
      'https://creativecommons.org/licenses/by-nc-sa/4.0/' => Resource.new('by-nc-sa', 'Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)'),
      'https://creativecommons.org/licenses/by-nc-nd/4.0/' => Resource.new('by-nc-nd', 'Attribution-NonCommercial-NoDerivatives 4.0 International (CC BY-NC-ND 4.0)'),
      'https://creativecommons.org/publicdomain/mark/1.0/' => Resource.new('pdm', 'Public Domain Mark 1.0'),
      'http://opendatacommons.org/licenses/pddl/1.0/' => Resource.new('pddl', 'Open Data Commons Public Domain Dedication and License 1.0'),
      'http://opendatacommons.org/licenses/by/1.0/' => Resource.new('odc-by', 'Open Data Commons Attribution License 1.0'),
      'http://opendatacommons.org/licenses/odbl/1.0/' => Resource.new('odc-odbl', 'Open Data Commons Open Database License 1.0')
    }.freeze

    # @return [String] the original xml with the legacy style rights added so that the description can be displayed.
    def to_xml
      license_uri = original.xpath('/rightsMetadata/use/license').text.presence
      return original.to_xml unless license_uri && LICENSE_CODES.key?(license_uri)

      use_node = original.xpath('/rightsMetadata/use').first
      license = LICENSE_CODES.fetch(license_uri)
      case license_uri
      when Cocina::FromFedora::License::NONE_LICENSE_URI
        use_node.add_child("<machine type=\"creativeCommons\">#{license.code}</machine>")
        use_node.add_child("<human type=\"creativeCommons\">#{license.label}</human>")
      when %r{://creativecommons.org/}
        use_node.add_child("<machine type=\"creativeCommons\" uri=\"#{license_uri}\">#{license.code}</machine>")
        use_node.add_child("<human type=\"creativeCommons\">#{license.label}</human>")
      when %r{://opendatacommons.org/}
        use_node.add_child("<machine type=\"openDataCommons\" uri=\"#{license_uri}\">#{license.code}</machine>")
        use_node.add_child("<human type=\"openDataCommons\">#{license.label}</human>")
      end
      original.to_xml
    end
  end
end
