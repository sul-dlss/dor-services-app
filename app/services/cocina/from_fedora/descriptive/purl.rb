# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Support for PURLs.
      class Purl
        def self.primary_purl_node(resource_element, purl)
          purl_nodes = resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS).select { |url_node| ::Purl.purl?(url_node.text) }

          return purl_nodes.find { |purl_node| purl_value(purl_node) == purl } if purl

          # Prefer a primary PURL node
          primary_purl_node = purl_nodes.find { |purl_node| purl_node[:usage] == 'primary display' }

          primary_purl_node || purl_nodes.first
        end

        def self.purl_note(purl_node)
          notes = []
          if purl_node[:note]
            notes << {
              value: purl_node['note'],
              appliesTo: [{ value: 'purl' }]
            }
          end
          if purl_node['displayLabel']
            notes << {
              value: purl_node['displayLabel'],
              type: 'display label',
              appliesTo: [{ value: 'purl' }]
            }
          end
          notes
        end

        def self.primary_purl_value(resource_element, purl)
          purl_value(primary_purl_node(resource_element, purl))
        end

        def self.purl_value(purl_node)
          # Note that normalizing http to https
          purl_node&.content&.sub(/^https?/, 'https')&.presence
        end
      end
    end
  end
end
