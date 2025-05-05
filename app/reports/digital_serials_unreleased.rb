# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerialsUnreleased.report"
class DigitalSerialsUnreleased
  # Report on possible digital serials, based on usage of note and title types in description plus catalog ids.
  # Excludes objects in the Google Books collection:
  # prod: druid:yh583fk3400; stage: druid:ks963md4872; qa: druid:kd593mk1175
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  # https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalog_record_id,
      jsonb_path_query(rov.description, 'strict $.title.** ? (@.type like_regex "part name").value') ->> 0 as title_part_name,
      jsonb_path_query(rov.description, 'strict $.title.** ? (@.type like_regex "part number").value') ->> 0 as title_part_number
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio")')
        AND jsonb_path_exists(rov.description, 'strict $.title.**.type ? (@ like_regex "part name|part number")')
        AND jsonb_path_exists(rov.structural, '$.isMemberOf[*] ? (@ != "druid:yh583fk3400")')
        AND ro.head_version_id = rov.id
        AND ro.object_type = 'dro';
  SQL

  def self.report
    puts 'druid,catalogRecordId,title_part_name,title_part_number,collection_name,collection_id'
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      next if released_to_searchworks?(druid: row['druid'])

      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        row['druid'],
        row['catalog_record_id'],
        row['title_part_name'],
        row['title_part_number'],
        "\"#{collection_name}\"",
        collection_druid
      ].join(',')
    end
  end

  def self.released_to_searchworks?(druid:)
    ReleaseTagService
      .for_public_metadata(cocina_object: CocinaObjectStore.find(druid))
      .any? { |tag| tag.to == 'Searchworks' && tag.release == true }
  end
end
