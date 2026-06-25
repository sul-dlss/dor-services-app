# frozen_string_literal: true

module Catalog
  # Builds a MARC record from a Folio instance hash
  class InstanceMarcBuilder
    # @see #build, #initialize
    def self.build(...)
      new(...).build
    end

    # @param instance_hash [Hash] Folio instance hash
    def initialize(instance_hash:)
      @instance_hash = instance_hash
    end

    # @return [MARC::Record] MARC record
    def build # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      MARC::Record.new.tap do |marc| # rubocop:disable Metrics/BlockLength
        marc.append(MARC::ControlField.new('001', instance_hash['hrid']))

        # Logic copied from https://github.com/sul-dlss/searchworks_traject_indexer/blob/ec1b1a2613894ee6c73e9b3e93e58996f6db5c91/lib/folio/marc_record_instance_mapper.rb#L14-L77
        Array(instance_hash['identifiers']).each do |identifier|
          case value = identifier.fetch('value')
          when /^([ a-z]{3}\d{8} |[ a-z]{2}\d{10})/ # LCCN
            marc.append(MARC::DataField.new('010', ' ', ' ', ['a', value]))
          when /^\d{9}[\dX].*/, /^\d{12}[\dX].*/ # ISBN
            marc.append(MARC::DataField.new('020', ' ', ' ', ['a', value]))
          when /^\d{4}-\d{3}[X\d]\D*$/ # ISSN
            marc.append(MARC::DataField.new('022', ' ', ' ', ['a', value]))
          when /^\(OCoLC.*/ # OCLC
            marc.append(MARC::DataField.new('035', ' ', ' ', ['a', value]))
          end
        end

        Array(instance_hash['languages']).each do |l|
          marc.append(MARC::DataField.new('041', ' ', ' ', ['a', l]))
        end

        Array(instance_hash['contributors']).each do |contrib|
          # personal name: 100/700
          field = MARC::DataField.new(contrib['primary'] ? '100' : '700', '1', '')
          # corp. name: 110/710, ind1: 2
          # meeting name: 111/711, ind1: 2
          field.append(MARC::Subfield.new('a', contrib['name']))

          marc.append(field)
        end

        marc.append(MARC::DataField.new('245', '0', '0', ['a', instance_hash['title']]))

        Array(instance_hash['editions']).each do |edition|
          marc.append(MARC::DataField.new('250', '0', '', ['a', edition]))
        end
        Array(instance_hash['publication']).each do |pub|
          field = MARC::DataField.new('264', '0', '0')
          field.append(MARC::Subfield.new('a', pub['place'])) if pub['place']
          field.append(MARC::Subfield.new('b', pub['publisher'])) if pub['publisher']
          field.append(MARC::Subfield.new('c', pub['dateOfPublication'])) if pub['dateOfPublication']
          marc.append(field)
        end
        Array(instance_hash['physicalDescriptions']).each do |desc|
          marc.append(MARC::DataField.new('300', '0', '0', ['a', desc]))
        end
        Array(instance_hash['publicationFrequency']).each do |freq|
          marc.append(MARC::DataField.new('310', '0', '0', ['a', freq]))
        end
        Array(instance_hash['publicationRange']).each do |range|
          marc.append(MARC::DataField.new('362', '0', '', ['a', range]))
        end
        Array(instance_hash['notes']).each do |note|
          marc.append(MARC::DataField.new('500', '0', '', ['a', note['note']]))
        end
        Array(instance_hash['series']).each do |series|
          marc.append(MARC::DataField.new('490', '0', '', ['a', folio_value(series)]))
        end
        Array(instance_hash['subjects']).each do |subject|
          marc.append(MARC::DataField.new('653', '', '', ['a', folio_value(subject)]))
        end

        marc.append(MARC::DataField.new('999', '', '', ['i', instance_hash['id']]))
      end
    end

    private

    attr_reader :instance_hash

    def folio_value(folio_data)
      return folio_data['value'] if folio_data.is_a?(Hash)

      folio_data
    end
  end
end
