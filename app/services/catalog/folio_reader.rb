# frozen_string_literal: true

module Catalog
  # Reader from Folio's JSON API to fetch marc json given a HRID or barcode
  class FolioReader
    attr_reader :folio_instance_hrid, :barcode

    FIELDS_TO_REMOVE = %w[001 003].freeze

    def initialize(folio_instance_hrid: nil, barcode: nil)
      @folio_instance_hrid = folio_instance_hrid
      @barcode = barcode
    end

    # @return [MARC::Record]
    # @raises FolioClient::UnexpectedResponse::ResourceNotFound, and FolioClient::UnexpectedResponse::MultipleResourcesFound, and Catalog::FolioReader::NotFound
    def to_marc
      # we need an instance_hrid to do a marc lookup, so fetch from the barcode if no instance_hrid was passed in
      @folio_instance_hrid = FolioClient.fetch_hrid(barcode:) if folio_instance_hrid.blank? && barcode.present?

      # at this point we must have a folio_instance_hrid (either passed in directly or fetched via the barcode)
      #  if nil, it was either not passed in or the barcode lookup didn't find anything
      raise FolioClient::UnexpectedResponse::ResourceNotFound if folio_instance_hrid.blank?

      # fetch the record from folio
      marc = MARC::Record.new_from_hash(FolioClient.fetch_marc_hash(instance_hrid: folio_instance_hrid))

      # build up new mutated record
      updated_marc = MARC::Record.new

      updated_marc.leader = marc.leader

      marc.fields.each do |field|
        updated_marc.fields << field unless FIELDS_TO_REMOVE.include? field.tag # explicitly remove all listed tags from the record
      end

      # explicitly inject the instance_hrid into the 001 field
      updated_marc.fields << MARC::ControlField.new('001', folio_instance_hrid)

      # explicitly inject FOLIO into the 003 field
      updated_marc.fields << MARC::ControlField.new('003', 'FOLIO')

      # return the mutated record
      updated_marc
    end
  end
end
