# frozen_string_literal: true

require 'parallel'
require 'tty-progressbar'

# Migrate Fedora objects to cocina JSON and xml datastreams stored in Postgres
#
# shared/log/migration_results/migration-results-(timestamp).txt - shows druid migrated, with success / missing / ERROR, etc.
# shared/log/fedora-migrator.log contains details of ERRORS (e.g. stacktrace)
class FedoraMigrator
  def initialize(processes:, druids: [], results_folder: 'migration_results')
    @druids = druids
    @processes = processes
    @results_folder = results_folder
    # rubocop:disable Rails/TimeZone
    # empirically proven to work, while a couple other approaches did not
    @results_file_name = "migration-results-#{Time.now.strftime('%Y-%m-%dT%H:%M:%S')}.txt"
    # rubocop:enable Rails/TimeZone

    return if Dir.exist?(results_folder)

    FileUtils.rm_rf(results_folder)
    FileUtils.mkdir_p(results_folder)
  end

  def run
    Rails.logger = ActiveSupport::Logger.new('log/fedora-migrator.log')
    Rails.logger.formatter = proc do |severity, time, _, msg|
      "#{time.strftime('%Y-%m-%d %H:%M:%S')} - #{severity} - #{msg}\n"
    end
    Rails.logger.datetime_format = '%Y-%m-%d %H:%M:%S'

    Rails.logger.info "Using #{processes} processes."
    File.open("#{results_folder}/#{results_file_name}", 'w') do |file|
      progress_bar = tty_progress_bar(druids.size)
      progress_bar.start
      Parallel.map(druids,
                   in_processes: processes,
                   finish: ->(druid, _, result) { on_finish(druid, result, progress_bar, file) }) do |druid|
        migrate(druid)
      end
    end
  end

  private

  attr_reader :druids, :results_folder, :results_file_name, :processes

  def on_finish(druid, result, progress_bar, file)
    progress_bar.advance(druid: druid)
    file.write("#{Time.zone.now.strftime('%Y-%m-%d %H:%M:%S')} #{druid}=#{result}\n")
  end

  # how many druids to process as a single advance unit of the progress bar
  def num_for_progress_advance(count)
    return 1 if count < 100

    count / 100
  end

  def tty_progress_bar(count)
    TTY::ProgressBar.new(
      'Migrating fedora objects to postgres [:bar] (:percent (:current/:total), rate: :rate/s, mean rate: :mean_rate/s, :elapsed total, ETA: :eta_time)',
      bar_format: :crate,
      advance: num_for_progress_advance(count),
      total: count
    )
  end

  def migrate(druid)
    Honeybadger.context(druid: druid, class: FedoraMigrator)
    cocina_object_store = CocinaObjectStore.new
    return 'already migrated' if cocina_object_store.ar_exists?(druid)

    fedora_obj = cocina_object_store.fedora_find(druid)

    return 'skipped' unless MigrationFilter.migrate?(Nokogiri::XML(fedora_obj.rels_ext.to_rels_ext))

    EventsMigrationService.migrate(fedora_obj)
    VersionMigrationService.migrate(fedora_obj)
    'success'
  rescue CocinaObjectStore::CocinaObjectNotFoundError => e
    Rails.logger.warn("#{druid} was not found during migration: #{e.inspect}")
    'missing'
  rescue Rubydora::FedoraInvalidRequest, StandardError => e
    Rails.logger.error("#{druid} errored during migration: #{e.inspect}")
    Rails.logger.error(e.backtrace)
    "ERROR: #{e}"
  end
end
