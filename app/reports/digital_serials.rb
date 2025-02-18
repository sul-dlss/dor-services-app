# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerials.report" > digital_serials.csv
class DigitalSerials
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  # https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalog_record_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").refresh') ->> 0 as refresh
      FROM repository_objects AS ro, repository_object_versions AS rov WHERE
        jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio")')
        AND (jsonb_path_exists(rov.description, 'strict $.title.**.type ? (@ like_regex "part name|part number")')
        OR jsonb_path_exists(rov.description, 'strict $.note.**.type ? (@ like_regex "date\/sequential designation")'))
        AND jsonb_path_exists(rov.structural, '$.isMemberOf[*] ? (@ != "druid:yh583fk3400")')
        AND ro.head_version_id = rov.id
        AND ro.object_type = 'dro';
  SQL

  def self.report
    puts 'druid,collection_id,collection_name,catalogRecordId,refresh'
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        row['druid'],
        collection_druid,
        "\"#{collection_name}\"",
        row['catalog_record_id'],
        row['refresh']
      ].join(',')
    end
  end
end
