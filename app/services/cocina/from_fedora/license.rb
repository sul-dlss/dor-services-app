# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the License URI.
    # First tries the license node.
    # If that is not found, try the open_data_commons/creative_commons accessor
    class License
      # Only used in some legacy ETDs and not actually permitted per the Project Chimera docs.
      NONE_LICENSE_URI = 'http://cocina.sul.stanford.edu/licenses/none'

      # @return [String] the URI of the license.
      def self.find(datastream)
        datastream.ng_xml.xpath('/rightsMetadata/use/license').text.presence || find_legacy_license(datastream)
      end

      def self.find_legacy_license(datastream)
        return NONE_LICENSE_URI if datastream.use_license.first == 'none'

        uris = datastream.ng_xml.xpath('/rightsMetadata/use/machine[@uri]').map { |node| node['uri'] }.reject(&:blank?)
        return uris.first if uris.present?

        if datastream.open_data_commons.first.present?
          Dor::OpenDataLicenseService.property(datastream.open_data_commons.first).uri
        elsif datastream.creative_commons.first.present?
          Dor::CreativeCommonsLicenseService.property(datastream.creative_commons.first).uri
        end
      end
      private_class_method :find_legacy_license
    end
  end
end
