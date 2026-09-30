# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DruidsRefreshTrue.report"
class DruidsRefreshTrue
  # Query for description and identification metadata for records where the folio catalogRecordId refresh is set to true.
  # and it's not a "google book"
  GOOGLE_BOOKS_APO = 'druid:bf569gy6501'
  SQL = <<~SQL.squish
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
      jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
      jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
      ro.object_type as object_type
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE
      jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == true)')
      AND NOT jsonb_path_exists(rov.administrative, '$.hasAdminPolicy ? (@ == "#{GOOGLE_BOOKS_APO}")')
      AND ro.head_version_id = rov.id;
  SQL

  def self.report
    puts %w[druid title collection_druid collection_title HRID object_type].join(',')
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        row['druid'],
        row['structured_title']&.delete("\n") || row['title'],
        collection_druid,
        collection_name,
        row['hrid'],
        row['object_type']
      ].to_csv
    end
  end
end
