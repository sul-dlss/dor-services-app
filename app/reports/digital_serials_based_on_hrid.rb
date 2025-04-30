# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerialsBasedOnHrid.report"
class DigitalSerialsBasedOnHrid
  # Query to find records where the HRID occurs in more than one record. Excludes those in the Google Books collection.
  # prod: druid:yh583fk3400; stage: druid:ks963md4872; qa: druid:kd593mk1175
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  # https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalog_record_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").refresh') ->> 0 as refresh
      FROM repository_objects AS ro, repository_object_versions AS rov WHERE
        jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio")')
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

    hrid_counts = sql_result_rows.group_by { |row| row['catalog_record_id'] }.transform_values(&:size)

    sql_result_rows.map do |row|
      next unless hrid_counts[row['catalog_record_id']] > 1

      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        row['druid'],
        collection_druid,
        "\"#{collection_name}\"",
        row['catalog_record_id'],
        row['refresh'],
        hrid_counts[row['catalog_record_id']]
      ].join(',')
    end
  end
end
