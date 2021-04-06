# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms a license URI into the xml to be written on a Fedora 3 datastream.
    class License
      def self.update(datastream, uri)
        new(datastream, uri).update
      end

      def initialize(datastream, uri)
        @datastream = datastream
        @uri = uri
      end

      def update
        initialize_use_node!
        clear_licenses
        if uri # don't build a license node if there is no license
          license_node = use_node.xpath('license').first || use_node.add_child('<license/>').first
          license_node.content = uri
        end

        datastream.ng_xml_will_change!
      end

      private

      attr_reader :uri, :datastream

      # Remove the legacy nodes
      def clear_licenses
        datastream.ng_xml.xpath('/rightsMetadata/use/machine[@type="openDataCommons"]').each(&:remove)
        datastream.ng_xml.xpath('/rightsMetadata/use/machine[@type="creativeCommons"]').each(&:remove)
        datastream.ng_xml.xpath('/rightsMetadata/use/human[@type="openDataCommons"]').each(&:remove)
        datastream.ng_xml.xpath('/rightsMetadata/use/human[@type="creativeCommons"]').each(&:remove)
      end

      def use_node
        datastream.ng_xml.xpath('/rightsMetadata/use').first
      end

      def initialize_use_node!
        datastream.add_child_node(datastream.ng_xml.root, :use) unless use_node
      end
    end
  end
end
