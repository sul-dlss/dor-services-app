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
    SELECT jsonb_path_query(description, '#{PURL_JSONB_PATH}') ->> 0 as purl,
           external_identifier,
           label,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM "dros" WHERE
           jsonb_array_length(jsonb_path_query_array(description, '#{EVENT_JSONB_PATH}')) > 1
           AND NOT jsonb_path_exists(dros.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId')
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
        collection_name = Collection.find_by(external_identifier: collection_druid)&.label

        [
          rows.first['purl'],
          rows.first['label'],
          "\"#{collection_name}\"",
          rows.first['apo']
        ].join(',')
      end
  end
end
