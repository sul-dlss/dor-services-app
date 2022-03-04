# frozen_string_literal: true

require 'tty-progressbar'

# Migrate Fedora objects to cocina JSON and xml datastreams stored in Postgres
class FedoraMigrator
  def initialize(druids: [], results_folder: 'migration_results')
    @druids = druids
    @results_folder = results_folder
    @results_file_name = "migration-results-#{Time.now.strftime('%Y-%m-%dT%H:%M:%S')}.txt"

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

    File.open("#{results_folder}/#{results_file_name}", 'w') do |file|
      progress_bar = tty_progress_bar(druids.size)
      progress_bar.start
      druids.each do |druid|
        progress_bar.advance(druid: druid)
        result = migrate(druid)
        file.write("#{druid}=#{result}\n")
      end
    end
  end

  private

  attr_reader :druids, :results_folder, :results_file_name

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
    fedora_obj = CocinaObjectStore.new.fedora_find(druid)

    return 'skipped' unless MigrationFilter.migrate?(Nokogiri::XML(fedora_obj.rels_ext.to_rels_ext))

    EventsMigrationService.migrate(fedora_obj)
    VersionMigrationService.migrate(fedora_obj)
    CocinaMigrationService.migrate(fedora_obj)
    'success'
  rescue CocinaObjectStore::CocinaObjectNotFoundError
    'missing'
  rescue StandardError => e
    Rails.logger.error("#{druid} errored during migration: #{e} - #{ e.backtrace}")
    "ERROR: #{e}"
  end
end
