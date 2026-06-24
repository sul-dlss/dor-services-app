# frozen_string_literal: true

module Catalog
  # Fetch a MARC record from Folio's source storage API and normalize abstracts
  class SourceStorageFetcher
    # @see #fetch, #initialize
    def self.fetch(...)
      new(...).fetch
    end

    # @param folio_instance_hrid [String] Folio instance HRID
    def initialize(folio_instance_hrid:)
      @folio_instance_hrid = folio_instance_hrid
    end

    # @return [Hash] MARC record as a hash
    # @raise [Catalog::MarcService::Error]
    def fetch
      FolioClient.fetch_marc_hash(instance_hrid: folio_instance_hrid).tap do |record_hash|
        # Only normalize if abstracts present
        abstracts = abstracts_from(record_hash)
        next if abstracts.blank?

        abstracts.each do |abstract|
          abstract.dig('520', 'subfields').each do |subfield|
            next unless subfield['a'].match?('{dollar}')

            subfield['a'] = subfield['a'].dup.gsub('{dollar}', '$')
          end
        end
      end
    end

    private

    attr_reader :folio_instance_hrid

    def abstracts_from(record_hash)
      record_hash.fetch('fields').select do |field|
        field.key?('520') && field.dig('520', 'ind1') == '3' && field.dig('520', 'subfields').any? do |subfield|
          subfield.key?('a')
        end
      end
    end
  end
end
