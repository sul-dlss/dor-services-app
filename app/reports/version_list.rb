# frozen_string_literal: true

# Exports metadata about all versions  in SDR
#  https://github.com/sul-dlss/dor-services-app/issues/4509
# Invoke via:
# bin/rails r -e production "VersionList.report"
class VersionList
  def self.report
    output_file = 'tmp/version_list_report.csv'

    CSV.open(output_file, 'w') do |csv|
      csv << %w[druid version description]

      num_versions = ObjectVersion.count
      puts "Found #{num_versions} object versions"
      i = 0
      ObjectVersion.find_each do |object_version|
        i += 1
        puts "#{i} of #{num_versions} : #{object_version.druid}"
        csv << [object_version.druid, object_version.version, object_version.description]
      end
      puts "Report written to #{output_file}"
    end
  end
end
