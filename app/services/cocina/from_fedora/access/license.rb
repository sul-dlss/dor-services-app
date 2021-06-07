# frozen_string_literal: true

module Cocina
  module FromFedora
    module Access
      # builds the License URI.
      # First tries the license node.
      # If that is not found, try the open_data_commons/creative_commons accessor
      class License
        # Only used in some legacy ETDs and not actually permitted per the Project Chimera docs.
        NONE_LICENSE_URI = 'http://cocina.sul.stanford.edu/licenses/none'
        OPENDATA_URIS = {
          'pddl' => 'https://opendatacommons.org/licenses/pddl/1-0/',
          'odc-by' => 'https://opendatacommons.org/licenses/by/1-0/',
          'odc-odbl' => 'https://opendatacommons.org/licenses/odbl/1-0/'
        }.freeze

        CREATIVECOMMONS_URIS = {
          'by' => 'https://creativecommons.org/licenses/by/3.0/legalcode',
          'by-sa' => 'https://creativecommons.org/licenses/by-sa/3.0/legalcode',
          'by-nd' => 'https://creativecommons.org/licenses/by-nd/3.0/legalcode',
          'by-nc' => 'https://creativecommons.org/licenses/by-nc/3.0/legalcode',
          'by-nc-sa' => 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode',
          'by-nc-nd' => 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode',
          'pdm' => 'https://creativecommons.org/publicdomain/mark/1.0/'
        }.freeze

        # @return [String] the URI of the license.
        def self.find(datastream)
          datastream.ng_xml.xpath('/rightsMetadata/use/license').text.presence || find_legacy_license(datastream)
        end

        def self.find_legacy_license(datastream)
          return NONE_LICENSE_URI if datastream.use_license.first == 'none'

          uris = datastream.ng_xml.xpath('/rightsMetadata/use/machine[@uri]').map { |node| node['uri'] }.reject(&:blank?)
          return uris.first if uris.present?

          if datastream.open_data_commons.first.present?
            OPENDATA_URIS.fetch(datastream.open_data_commons.first)
          elsif datastream.creative_commons.first.present?
            CREATIVECOMMONS_URIS.fetch(datastream.creative_commons.first)
          end
        end
        private_class_method :find_legacy_license
      end
    end
  end
end
