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

        def self.primary_purl_node(resource_element, purl)
          purl_nodes = resource_element.xpath('mods:location/mods:url', mods: DESC_METADATA_NS).select { |url_node| purl?(url_node) }

          return purl_nodes.find { |purl_node| purl_node.content == purl } if purl

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

        def self.purl_for(druid)
          return nil if druid.nil?

          "http://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
        end
      end
    end
  end
end
