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
        data_for_marc[:identifier],
        '.856. ',
        data_for_marc[:indicators],
        data_for_marc[:subfield_z],
        data_for_marc[:subfield_u],
        data_for_marc[:subfield_x1],
        data_for_marc[:subfield_x2],
        data_for_marc[:subfield_x4],
        data_for_marc[:subfield_x5],
        data_for_marc[:subfield_x6],
        data_for_marc[:subfield_x7],
        data_for_marc[:subfield_x8]
      ].join
    end

    def previous_identifiers
      data_for_marc[:previous_ckeys].map { |previous_ckey| "#{previous_ckey}\\n" }.join
    end
  end
end
