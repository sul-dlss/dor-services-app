# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DruidsRefreshFalse.report"
class DruidsRefreshFalse
  # Query for description and identification metadata for records where the folio catalogRecordId refresh is set to false.
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == false).catalogRecordId') ->> 0 as catalog_record_id,
      jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
      jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
      ro.object_type as object_type,
      rov.label as label
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE
      jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == false)')
      AND ro.head_version_id = rov.id;
  SQL

  def self.report
    puts %w[catalogRecordId druid object_type label structured_title title collection_name collection_druid].join(',')
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
        row['label'],
        row['structured_title']&.delete('\n'),
        row['title'],
        collection_name,
        collection_druid
      ].to_csv
    end
  end
end
