# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps subject nodes from MODS to cocina
      class Subject
        # @param [Nokogiri::XML::Document] ng_xml the descriptive metadata XML
        # @return [Hash] a hash that can be mapped to a cocina model
        def self.build(ng_xml)
          new(ng_xml).build
        end

        def initialize(ng_xml)
          @ng_xml = ng_xml
        end

        def build
          topics.map do |topic|
            { value: topic.text, type: 'topic' }
          end
        end

        private

        attr_reader :ng_xml

        def topics
          ng_xml.xpath('//mods:subject/mods:topic', mods: DESC_METADATA_NS)
        end
      end
    end
  end
end
