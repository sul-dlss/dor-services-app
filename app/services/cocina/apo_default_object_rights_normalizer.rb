# frozen_string_literal: true

module Cocina
  # Normalizes a Fedora APO default object rights, accounting for differences between Fedora APOs and APOs generated from Cocina.
  class ApoDefaultObjectRightsNoramlizer
    # @param [Nokogiri::Document] rights_ng_xml default_object_rights_xml to be normalized
    # @param [String] druid
    # @return [Nokogiri::Document] normalized default_object_rights
    def self.normalize(rights_ng_xml:, druid:)
      ApoDefaultObjectRightsNoramlizer.new(rights_ng_xml: rights_ng_xml, druid: druid).normalize
    end

    def initialize(rights_ng_xml:, druid:)
      @ng_xml = rights_ng_xml.dup
      @ng_xml.encoding = 'UTF-8' if @ng_xml.respond_to?(:encoding=)
      @druid = druid
    end

    def normalize
      normalize_default_object_rights
      remove_empty_elements(ng_xml.root) # this must be last
      ng_xml
    end

    private

    attr_reader :ng_xml, :druid

    def normalize_default_object_rights
      xml = ng_xml.to_s

      regenerate_ng_xml(xml)
    end

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
