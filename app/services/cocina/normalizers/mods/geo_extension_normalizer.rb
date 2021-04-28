# frozen_string_literal: true

module Cocina
  module Normalizers
    module Mods
      # Normalizes a Fedora MODS document for geo extension elements.
      class GeoExtensionNormalizer
        # @param [Nokogiri::Document] mods_ng_xml MODS to be normalized
        # @param [String] druid
        # @return [Nokogiri::Document] normalized MODS
        def self.normalize(mods_ng_xml:, druid:)
          new(mods_ng_xml: mods_ng_xml, druid: druid).normalize
        end

        def initialize(mods_ng_xml:, druid:)
          @ng_xml = mods_ng_xml.dup
          @ng_xml.encoding = 'UTF-8'
          @druid = druid
        end

        def normalize
          normalize_geo_purl
          normalize_dc_image
          normalize_gml_id
          normalize_empty_resource
          ng_xml
        end

        private

        attr_reader :ng_xml, :druid

        def normalize_geo_purl
          ng_xml.root.xpath('//mods:extension[@displayLabel="geo"]//rdf:Description',
                            mods: ModsNormalizer::MODS_NS,
                            rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').each do |node|
            node['rdf:about'] = "http://purl.stanford.edu/#{druid.delete_prefix('druid:')}"
          end
        end

        def normalize_dc_image
          ng_xml.root.xpath('//mods:extension[@displayLabel="geo"]//dc:type[text() = "image"]',
                            mods: ModsNormalizer::MODS_NS,
                            dc: 'http://purl.org/dc/elements/1.1/').each do |node|
            node.content = 'Image'
          end
        end

        def normalize_gml_id
          ng_xml.root.xpath("//gml:Point[@gml:id='ID']", gml: 'http://www.opengis.net/gml/3.2/').each do |point_node|
            point_node.delete('id')
          end
        end

        def normalize_empty_resource
          ng_xml.root.xpath('//dc:coverage[@rdf:resource = ""]',
                            dc: 'http://purl.org/dc/elements/1.1/',
                            rdf: 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').each do |coverage_node|
            coverage_node.delete('resource')
          end
        end
      end
    end
  end
end
