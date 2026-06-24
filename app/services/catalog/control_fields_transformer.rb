# frozen_string_literal: true

module Catalog
  # Transforms control fields in a MARC record to match the Folio instance HRID and catalog source
  class ControlFieldsTransformer
    # @see #transform, #initialize
    def self.transform(...)
      new(...).transform
    end

    FIELDS_TO_REPLACE = %w[001 003].freeze

    # @param marc_hash [Hash] MARC record as a hash
    def initialize(marc_hash:, folio_instance_hrid:)
      @updated_record = MARC::Record.new_from_hash(marc_hash).dup
      @folio_instance_hrid = folio_instance_hrid
    end

    # @return [MARC::Record] Transformed MARC record with 001 and 003 fields updated
    def transform
      updated_record.fields(FIELDS_TO_REPLACE).each(&:delete)
      updated_record.fields << MARC::ControlField.new('001', folio_instance_hrid)
      updated_record.fields << MARC::ControlField.new('003', 'FOLIO')
      updated_record
    end

    private

    attr_reader :folio_instance_hrid, :updated_record
  end
end
