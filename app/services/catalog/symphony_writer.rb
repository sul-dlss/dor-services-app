# frozen_string_literal: true

require 'open3'
require 'shellwords'

module Catalog
  # Writes the stub 856 record for sending to symphony
  class SymphonyWriter
    def self.save(cocina_object:, marc_856_data:)
      new(cocina_object:, marc_856_data:).save
    end

    def initialize(cocina_object:, marc_856_data:)
      @cocina_object = cocina_object
      @marc_856_data = marc_856_data
    end

    def save
      return if catkeys.empty? && previous_catkeys.empty?

      symphony_file_name = "#{Settings.release.symphony_path}/sdr-purl-856s"
      records.each do |record|
        command = "#{Settings.release.write_856_script} #{Shellwords.escape(new_856_record(record))} #{Shellwords.escape(symphony_file_name)}"
        run_write_script(command)
      end
    end

    def run_write_script(command)
      Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
        stdout_text = stdout.read
        stderr_text = stderr.read
        raise "Error in writing 856 file using the command #{command}\n#{stdout_text}\n#{stderr_text}" if stdout_text.length.positive? || stderr_text.length.positive?
      end
    end

    private

    attr_reader :marc_856_data, :cocina_object

    def records
      # first create "blank" records for any previous catkeys
      new_records = previous_catkeys.map { |previous_catkey| new_identifier_record(previous_catkey) }

      # For only the first current catkey, add the 856 record if it is released to searchworks
      # Otherwise, just add the "blank" record
      unless catkeys.empty?
        catkey = catkeys.first
        new_record = new_identifier_record(catkey)
        new_record.merge!(marc_856_data) if released_to_searchworks?
        new_records << new_record
      end
      new_records
    end

    def new_856_record(record)
      return identifier_prefix(record[:catalog_record_id], record[:druid]) if record[:subfields].blank?

      "#{identifier_prefix(record[:catalog_record_id], record[:druid])}.856. #{marc_856_for(record)}"
    end

    def new_identifier_record(catalog_record_id)
      {
        catalog_record_id:,
        druid:
      }
    end

    def druid
      @druid ||= @cocina_object.externalIdentifier.delete_prefix('druid:')
    end

    def identifier_prefix(catalog_record_id, druid)
      "#{catalog_record_id}\t#{druid}\t"
    end

    def marc_856_for(record)
      marc856 = record[:indicators]
      record[:subfields].each do |subfield|
        next if subfield[:value].blank?

        marc856 += "|#{subfield[:code]}#{subfield[:value]}"
      end

      marc856
    end

    def catkeys
      @catkeys ||= fetch_catalog_record_ids(current: true)
    end

    def previous_catkeys
      @previous_catkeys ||= fetch_catalog_record_ids(current: false)
    end

    # List of current or previous ckeys for the cocina object (depending on parameter passed)
    # @param current [boolean] if you want the current or previous ckeys
    # @return [Array] previous or current catkeys for the object in an array, empty array if none exist
    def fetch_catalog_record_ids(current:)
      return [] unless @cocina_object.respond_to?(:identification) && @cocina_object.identification

      ckey_type = current ? 'symphony' : 'previous symphony'
      @cocina_object.identification.catalogLinks.select { |link| link.catalog == ckey_type }.map(&:catalogRecordId)
    end

    def released_to_searchworks?
      released_for = ::ReleaseTags.for(cocina_object:)
      rel = released_for.transform_keys { |key| key.to_s.upcase }
      rel.dig('SEARCHWORKS', 'release').presence || false
    end
  end
end
