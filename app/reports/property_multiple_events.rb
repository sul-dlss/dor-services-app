# frozen_string_literal: true

# Generate a report of DROs that have mutiple events but no folio HRID
#
# bin/rails r -e production "PropertyMultipleEvents.report"
#
class PropertyMultipleEvents
  # find events in cocina objects
  EVENT_JSONB_PATH = '$.event[*] ? (@ != null)'
  PURL_JSONB_PATH = 'strict $.purl'

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{PURL_JSONB_PATH}') ->> 0 as purl,
           ro.external_identifier,
           rov.label,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_array_length(jsonb_path_query_array(rov.description, '#{EVENT_JSONB_PATH}')) > 1
           AND NOT jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId')
  SQL

  def self.report
    puts 'purl,title,collection name,APO'

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |_id, rows|
        collection_druid = rows.first['collection_id']
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

        [
          rows.first['purl'],
          rows.first['label'],
          collection_name,
          rows.first['apo']
        ].to_csv
      end
  end
end
