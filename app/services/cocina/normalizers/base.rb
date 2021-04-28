# frozen_string_literal: true

module Cocina
  module Normalizers
    # Shared methods available to normalizer class instances
    module Base
      def regenerate_ng_xml(xml)
        @ng_xml = Nokogiri::XML(xml) { |config| config.default_xml.noblanks }
      end

      # remove all empty elements that have no attributes and no children, recursively
      def remove_empty_elements(start_node)
        return unless start_node

        # remove node if there are no element children, there is no text value and there are no attributes
        if start_node.elements.size.zero? &&
           start_node.text.blank? &&
           start_node.attributes.size.zero? &&
           start_node.name != 'etal'
          parent = start_node.parent
          start_node.remove
          remove_empty_elements(parent) # need to call again after child has been deleted
        else
          start_node.element_children.each { |e| remove_empty_elements(e) }
        end
      end
    end
  end
end
