# frozen_string_literal: true

# Exports publish information about druids lacking public cocina.
#   https://github.com/sul-dlss/dor-services-app/issues/5181
# Input is a CSV of druids generated on purl-fetcher with the query:
#   Purl.status('public').where.missing(:public_json).pluck(:druid)
# Invoke via:
# bin/rails r -e production "PublishStatus.report('druids.csv')"
class PublishStatus
  def self.report(druids_file)
    druids = File.readlines(druids_file).map(&:strip)
    output_file = 'tmp/publish_status_report.csv'

    CSV.open(output_file, 'w') do |csv|
      csv << %w[druid closed publishable not_dark first_published]

      druids.each do |druid|
        object = RepositoryObject.where(external_identifier: druid).first
        latest = object.head_version
        not_dark = latest.access.fetch('view') != 'dark'

        milestones = workflow_client.milestones(druid:)
        published = milestones.filter { |milestone| milestone[:version] == '1' && milestone[:milestone] == 'published' }
        date = published.first[:at] if published.any?

        csv << [druid, object.closed?, object.publishable?, not_dark, date]
      end
      puts "Report written to #{output_file}"
    end
  end

  def self.workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
