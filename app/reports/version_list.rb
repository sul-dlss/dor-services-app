# frozen_string_literal: true

# Exports metadata about all versions  in SDR
#  https://github.com/sul-dlss/dor-services-app/issues/4509
# Invoke via:
# bin/rails r -e production "VersionList.report"
class VersionList
  def self.report
    puts %w[druid version description].join(',')

    ObjectVersion.find_each do |object_version|
      puts [object_version.druid, object_version.version, object_version.description].join(',')
    end
  end
end
