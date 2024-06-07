# frozen_string_literal: true

# Compare SDR versions against Preservation versions
#  https://github.com/sul-dlss/dor-services-app/issues/5074
# Invoke via:
# bin/rails r -e production "PreservationVersions.report"
class PreservationVersions
  def self.report
    new.report
  end

  def report
    # Objects with a closed version, indicating they have been accessioned.
    data = RepositoryObject.joins(:head_version).where.not(last_closed_version: nil).pluck(:external_identifier, :version)

    progress_bar = tty_progress_bar(data.length)
    progress_bar.start

    results = Parallel.map(data.each_slice(2500),
                           in_processes: 3,
                           finish: ->(finish_data, _, _) { progress_bar.advance(finish_data.length) }) do |data_slice|
      data_slice.map do |druid, version|
        begin
          preservation_version = Preservation::Client.objects.current_version(druid)
        rescue Preservation::Client::NotFoundError
          preservation_version = nil
        end
        preservation_version == version ? nil : [druid, version, preservation_version]
      end
    end.flatten(1).compact

    CSV.open('preservation_versions_report.csv', 'w') do |csv|
      csv << %w[druid version preservation_version]
      results.each { |result| csv << result }
    end
  end

  def tty_progress_bar(count)
    TTY::ProgressBar.new(
      '[:bar] (:percent (:current/:total), rate: :rate/s, mean rate: :mean_rate/s, :elapsed total, ETA: :eta_time)',
      bar_format: :box,
      advance: num_for_progress_advance(count),
      total: count
    )
  end

  def num_for_progress_advance(count)
    return 1 if count < 100

    count / 100
  end
end
