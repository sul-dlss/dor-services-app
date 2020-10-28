# frozen_string_literal: true

module Cocina
  module FromFedora
    class Descriptive
      # Maps titles
      class HydrusDefaultTitleBuilder
        # @param [Nokogiri::XML::Document] _ng_xml the descriptive metadata XML
        # @return [Array] a hash that can be mapped to a cocina model
        # @raises [Mapper::MissingTitle]
        def self.build(_ng_xml)
          [{ value: 'Hydrus' }]
        end
      end
    end
  end
end
