# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Support for PURLs.
      class Purl
        PURL_REGEX = %r{^https?://purl.stanford.edu/}.freeze

        def self.purl?(node)
          PURL_REGEX.match(node.text)
        end

        def self.primary_purl_node(resource_element)
          purl_nodes = resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS).select { |url_node| purl?(url_node) }
          # Prefer a primary PURL node
          primary_purl_node = purl_nodes.find { |purl_node| purl_node[:usage] == 'primary display' }

          primary_purl_node || purl_nodes.first
        end
      end
    end
  end
end
