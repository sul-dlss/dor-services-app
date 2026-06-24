# frozen_string_literal: true

module Catalog
  # Normalizes MARC records fetched from FOLIO, specifically replacing "{dollar}" with "$" in abstract fields (520)
  class AbstractNormalizer
    # @see #normalize, #initialize
    def self.normalize(...)
      new(...).normalize
    end

    # @param record_hash [Hash] MARC record as a hash
    def initialize(record_hash:)
      @record_hash = record_hash
    end

    # @return [Hash] MARC record as a hash
    def normalize
      abstracts_from(record_hash).each do |abstract|
        abstract.dig('520', 'subfields').each do |subfield|
          next unless subfield['a'].match?('{dollar}')

          subfield['a'] = subfield['a'].dup.gsub('{dollar}', '$')
        end
      end

      record_hash
    end

    private

    attr_reader :record_hash

    def abstracts_from(record_hash)
      record_hash.fetch('fields').select do |field|
        field.key?('520') && field.dig('520', 'ind1') == '3' && field.dig('520', 'subfields').any? do |subfield|
          subfield.key?('a')
        end
      end
    end
  end
end
