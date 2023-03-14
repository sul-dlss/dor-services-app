# frozen_string_literal: true

require 'open3'
require 'shellwords'

module Catalog
  # Writes the stub 856 record for sending to symphony
  class SymphonyWriter
    def self.save(marc_856_records)
      new.save(marc_856_records)
    end

    def save(marc_856_records)
      return if marc_856_records.blank?

      symphony_file_name = "#{Settings.release.symphony_path}/sdr-purl-856s"
      marc_856_records.each do |record|
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

    def new_856_record(record)
      return identifier_prefix(record[:catalog_record_id], record[:druid]) if record[:subfields].blank?

      "#{identifier_prefix(record[:catalog_record_id], record[:druid])}.856. #{marc_856_for(record)}"
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
  end
end
