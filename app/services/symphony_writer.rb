# frozen_string_literal: true

require 'open3'
require 'shellwords'

# Writes a MARC record for sending to symphony
class SymphonyWriter
  def self.save(marc_records)
    new.save(marc_records)
  end

  def save(marc_records)
    return if marc_records.blank?

    symphony_file_name = "#{Settings.release.symphony_path}/sdr-purl-856s"
    marc_records.each do |marc_record|
      command = "#{Settings.release.write_marc_script} #{Shellwords.escape(marc_record)} #{Shellwords.escape(symphony_file_name)}"
      run_write_script(command)
    end
  end

  def run_write_script(command)
    Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
      stdout_text = stdout.read
      stderr_text = stderr.read
      raise "Error in writing marc_record file using the command #{command}\n#{stdout_text}\n#{stderr_text}" if stdout_text.length.positive? || stderr_text.length.positive?
    end
  end
end
