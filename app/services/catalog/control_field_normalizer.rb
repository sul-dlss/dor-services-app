# frozen_string_literal: true

module Catalog
  # Normalizes control fields in a MARC record to match the Folio instance HRID and catalog source
  class ControlFieldNormalizer
    # @see #normalize, #initialize
    def self.normalize(...)
      new(...).normalize
    end

    # @param record_hash [Hash] MARC record as a hash
    def initialize(record_hash:, folio_instance_hrid:)
      @updated_hash = record_hash.dup
      @folio_instance_hrid = folio_instance_hrid
    end

    # @return [Hash] Normalized MARC record hash with 001 and 003 fields updated
    def normalize
      updated_hash['001'] = folio_instance_hrid
      updated_hash['003'] = 'FOLIO'
      updated_hash
    end

    private

    attr_reader :folio_instance_hrid, :updated_hash
  end
end
