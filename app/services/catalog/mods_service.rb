# frozen_string_literal: true

module Catalog
  # MODS service for retrieving a MODS records
  class ModsService
    class TransformError < MarcService::MarcServiceError; end

    # @see #initialize
    def self.mods(...)
      new(...).mods
    end

    def initialize(marc_service:)
      @marc_service = marc_service
    end

    # @return [String] MODS XML
    # @raise CatalogResponseError
    def mods
      @mods ||= mods_ng.to_xml
    end

    # @return [Nokogiri::XML::Document] MODS XML
    # @raise CatalogResponseError
    # @raise CatalogRecordNotFoundError
    def mods_ng
      @mods_ng ||= begin
        marc_to_mods_xslt.transform(marc_service.marcxml_ng)
      rescue MarcService::CatalogRecordNotFoundError => e
        raise e
      rescue RuntimeError => e
        raise TransformError, "Error transforming MARC to MODS: #{e.message}"
      end
    end

    private

    attr_reader :marc_service

    def marc_to_mods_xslt
      @marc_to_mods_xslt ||= Nokogiri::XSLT(File.open(Rails.root.join('app/xslt/MARC21slim2MODS3-7_SDR_v2-8.xsl')))
    end
  end
end
