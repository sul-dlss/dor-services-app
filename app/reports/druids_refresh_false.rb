# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DruidsRefreshFalse.report" > druids_do_not_refresh.csv
class DruidsRefreshFalse
  # Query to find items where refresh is set to false.
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalog_record_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").refresh') ->> 0 as refresh,
      ro.object_type as object_type,
      rov.label as label
      FROM repository_objects AS ro, repository_object_versions AS rov WHERE
        jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == false)')
        AND ro.head_version_id = rov.id;
  SQL

  def self.report
    puts 'catalogRecordId,druid,object_type,label,collection_name,collection_druid,refresh'
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        row['catalog_record_id'],
        row['druid'],
        row['object_type'],
        "\"#{row['label']}\"",
        "\"#{collection_name}\"",
        collection_druid,
        row['refresh']
      ].join(',')
    end
  end
end
