# frozen_string_literal: true

module Catalog
  # Reader from Folio's JSON API to fetch marc json given a HRID or barcode
  class FolioReader
    def self.to_marc(folio_instance_hrid: nil, barcode: nil)
      new(folio_instance_hrid:, barcode:).to_marc
    end

    attr_reader :folio_instance_hrid, :barcode

    FIELDS_TO_REMOVE = %w[001 003].freeze

    def initialize(folio_instance_hrid: nil, barcode: nil)
      @folio_instance_hrid = folio_instance_hrid
      @barcode = barcode
    end

    # @return [MARC::Record]
    # @raise FolioClient::UnexpectedResponse::ResourceNotFound, and
    # FolioClient::UnexpectedResponse::MultipleResourcesFound, and Catalog::FolioReader::NotFound
    def to_marc # rubocop:disable Metrics/AbcSize
      # we need an instance_hrid to do a marc lookup, so fetch from the barcode if no instance_hrid was passed in
      @folio_instance_hrid ||= FolioClient.fetch_hrid(barcode:)

      raise FolioClient::ResourceNotFound if folio_instance_hrid.blank?

      # fetch the record from folio
      marc = MARC::Record.new_from_hash(normalized_marc_hash)
      # build up new mutated record
      updated_marc = MARC::Record.new
      updated_marc.leader = marc.leader
      marc.fields.each do |field|
        # explicitly remove all listed tags from the record
        updated_marc.fields << field unless FIELDS_TO_REMOVE.include? field.tag
      end
      # explicitly inject the instance_hrid into the 001 field
      updated_marc.fields << MARC::ControlField.new('001', folio_instance_hrid)
      # explicitly inject FOLIO into the 003 field
      updated_marc.fields << MARC::ControlField.new('003', 'FOLIO')
      updated_marc
    end

    private

    def normalized_marc_hash # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      FolioClient.fetch_marc_hash(instance_hrid: folio_instance_hrid).tap do |record_hash|
        # Only normalize if abstracts present
        abstracts = record_hash.fetch('fields').select do |field|
          field.key?('520') && field.dig('520', 'ind1') == '3' && field.dig('520', 'subfields').any? do |subfield|
            subfield.key?('a')
          end
        end
        next if abstracts.blank?

        abstracts.each do |abstract|
          abstract.dig('520', 'subfields').each do |subfield|
            next unless subfield['a'].match?('{dollar}')

            subfield['a'] = subfield['a'].dup.gsub('{dollar}', '$')
          end
        end
      end
    end
  end
end
