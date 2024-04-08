# frozen_string_literal: true

# Given a list of druids, dump the cocina as line delimited JSON to stdout.
#
# Invoke via:
# bin/rails r -e production "ExportCocinaFromDruidList.report(druid_list_filename: '/my/druid_list.txt')"
#
# * The input druid list should have one druid per line, namespaced (i.e. with the 'druid:' prefix).
# * druid_list_filename should be the full path.  There won't be shell expansion, so e.g. "~" for home dir won't work.
# * The output will be sent to stdout.
#   * You probably want to redirect the output to a file.
#   * If you have a large druid list, as this report is meant to handle, you also may want to stream the output through
#     gzip, instead of to a raw .jsonl file.  e.g.:
#     bin/rails r -e production "ExportCocinaFromDruidList.report(druid_list_filename: '/my/druid_list.txt')" | gzip > druid_list.cocina.`date -Iseconds`.jsonl.gz
#     * You can page through it with zless, or search it with zgrep, if you want to do some basic viewing without unzipping it.
#     * 'zcat myoutputfile.jsonl.gz | wc -l' is quick way to make sure the gzip output contains the expected number of records (can throw errors if output still being written)
#
# Meant for running exports that might be too large for Argo's ExportCocinaJsonJob, good for running in screen:
# * all status related output is logged; report output goes to stdout for redirection to a file as desired by the caller
# * reads the input file one line at a time without loading the whole thing; only keeps one output row in memory at a time
class ExportCocinaFromDruidList
  def self.report(...)
    new(...).report
  end

  def initialize(druid_list_filename:)
    @druid_list_filename = druid_list_filename
  end

  attr_reader :druid_list_filename

  def report
    raise "Input file missing: #{druid_list_filename}" unless File.exist?(druid_list_filename)

    logger.info("Dumping cocina for '#{druid_list_filename}' to stdout")

    logger.info("#{druid_list_filename} contains #{num_input_lines} entries")

    num_processed = 0
    File.foreach(druid_list_filename) do |raw_line|
      num_processed += 1

      druid = raw_line.chomp
      if druid.empty? || !DruidTools::Druid.valid?(druid, true)
        logger.warn("'#{druid}' is not actually a valid druid, skipping")
        next
      end

      # The :lock field is unnecessary for this report, since we won't be using this cocina for editing and
      # pushing updates back to DB.
      # This produces output equivalent to taking cocina_object.to_json and manually removing the lock field
      # from that string.
      cocina_object_json = CocinaObjectStore.find(druid).to_h.except(:lock).to_json

      output_record_line(cocina_object_json)

      log_progress(num_processed)
    rescue StandardError => e
      logger.error("Unexpected error trying to output cocina for druid: #{e}")
    end

    logger.info("Dumped cocina for '#{druid_list_filename}' to stdout")
  end

  private

  def logger
    @logger ||= Logger.new(Rails.root.join('log', "#{self.class.name}.log"))
  end

  def num_input_lines
    @num_input_lines ||= `wc -l #{druid_list_filename}`.match(/(\d+)/).captures.first.to_i
  end

  def progress_notification_chunk_size
    @progress_notification_chunk_size ||= num_input_lines / 10
  end

  def log_progress(num_processed)
    return unless (num_processed % progress_notification_chunk_size).zero?

    logger.info("processed #{num_processed} input lines of #{num_input_lines} (#{num_processed.to_f / num_input_lines} percent complete)")
  end

  def output_record_line(str)
    puts "#{str}\n"
  end
end
