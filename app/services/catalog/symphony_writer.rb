# frozen_string_literal: true

require 'open3'
require 'shellwords'

module Catalog
  # Writes the stub 856 record for sending to symphony
  class SymphonyWriter
    def self.save(data_for_marc)
      new(data_for_marc).save
    end

    def initialize(data_for_marc)
      @data_for_marc = data_for_marc
    end

    def save
      return if @data_for_marc.blank?

      symphony_file_name = "#{Settings.release.symphony_path}/sdr-purl-856s"
      command = "#{Settings.release.write_856_script} '#{Shellwords.escape(generate_856_record)}' #{Shellwords.escape(symphony_file_name)}"
      run_write_script(command)
    end

    def run_write_script(command)
      Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
        stdout_text = stdout.read
        stderr_text = stderr.read
        raise "Error in writing 856 file using the command #{command}\n#{stdout_text}\n#{stderr_text}" if stdout_text.length.positive? || stderr_text.length.positive?
      end
    end

    attr_reader :data_for_marc

    private

    def generate_856_record
      [
        previous_identifiers,
        data_for_marc[:identifiers][:ckey],
        '.856. ',
        indicator,
        permissions,
        purl,
        type,
        barcode,
        thumb,
        collections,
        parts,
        rights
      ].join
    end

    def previous_identifiers
      data_for_marc[:previous_ckeys].map { |previous_ckey| "#{previous_ckey[:ckey]}\\t#{previous_ckey[:druid]} \\n" }.join
    end

    def indicator
      data_for_marc[:indicator] ? '40' : '41'
    end

    def permissions
      "|z#{data_for_marc[:permissions]}"
    end

    def purl
      "|u#{data_for_marc[:purl]}|xSDR-PURL"
    end

    def type
      "|x#{data_for_marc[:object_type]}"
    end

    def barcode
      return if data_for_marc[:barcode].nil?

      "|xbarcode:#{data_for_marc[:barcode]}"
    end

    def thumb
      return if data_for_marc[:thumb].nil?

      "|xfile:#{data_for_marc[:thumb]}"
    end

    def collections
      return unless data_for_marc[:collections]

      ''.tap do |coll_string|
        data_for_marc[:collections].each do |collection|
          coll_string += "|x#{collection[:druid]}:#{collection[:ckey]}:#{collection[:label]}"
        end
      end
    end

    def parts
      return unless data_for_marc[:part]

      part_string = ''
      part_string += "|x#{data_for_marc[:part][:label]}" if data_for_marc[:part][:label]
      part_string += "|x#{data_for_marc[:part][:sort]}" if data_for_marc[:part][:sort]

      part_string
    end

    def rights
      data_for_marc[:rights].map { |value| "|x#{value}" }.join
    end
  end
end
