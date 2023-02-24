# frozen_string_literal: true

module Catalog
  # Reader from Folio's JSON API to fetch marc json given a HRID or barcode
  class FolioReader
    class NotFound < StandardError; end

    attr_reader :folio_instance_hrid, :barcode

    def initialize(folio_instance_hrid: nil, barcode: nil)
      @folio_instance_hrid = folio_instance_hrid
      @barcode = barcode
    end

    # @return [MARC::Record]
    # @raises FolioClient::UnexpectedResponse::ResourceNotFound, and FolioClient::UnexpectedResponse::MultipleResourcesFound
    def to_marc
      # we need a instance_hrid to do a marc lookup, so fetch from the barcode if none exists
      @folio_instance_hrid = FolioClient.fetch_hrid(barcode:) if folio_instance_hrid.blank?

      # at this point we must have a folio_instance_hrid (either passed in directly or fetched via the barcode)
      #  if nil, it was either not passed in or the barcode lookup didn't find anything
      raise NotFound if folio_instance_hrid.blank?

      MARC::Record.new_from_hash(FolioClient.fetch_marc_hash(instance_hrid: folio_instance_hrid))
    end
  end
end
