# frozen_string_literal: true

module Publish
  class DublinCoreService
    MODS_TO_DC_XSLT = Nokogiri::XSLT(File.new(File.expand_path(File.dirname(__FILE__) + '/mods2dc.xslt')))
    XMLNS_OAI_DC = 'http://www.openarchives.org/OAI/2.0/oai_dc/'
    class CrosswalkError < Dor::DataError; end

    # @param [Dor::Item] work the item to generate the DublinCore for.
    def initialize(work)
      @work = work
    end

    # Generates Dublin Core from the MODS in the descMetadata datastream using the LoC mods2dc stylesheet
    #    Should not be used for the Fedora DC datastream
    # @raise [CrosswalkError] Raises an Exception if the generated DC is empty or has no children
    # @return [Nokogiri::XML::Document] the DublinCore XML document object
    def ng_xml
      dc_doc = MODS_TO_DC_XSLT.transform(desc_md)
      dc_doc.xpath('/oai_dc:dc/*[count(text()) = 0]', oai_dc: XMLNS_OAI_DC).remove # Remove empty nodes
      raise CrosswalkError, "DublinCoreService#ng_xml produced incorrect xml (no root):\n#{dc_doc.to_xml}" if dc_doc.root.nil?
      raise CrosswalkError, "DublinCoreService#ng_xml produced incorrect xml (no children):\n#{dc_doc.to_xml}" if dc_doc.root.children.empty?

      dc_doc
    end

    # @return [String] the DublinCore XML document object
    delegate :to_xml, to: :ng_xml

    private

    def desc_md
      PublicDescMetadataService.new(work).ng_xml(include_access_conditions: false)
    end

    attr_reader :work
  end
end
