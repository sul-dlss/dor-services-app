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
      jsonb_path_query_array(rov.description, 'strict $.title[0].** ? (@.type like_regex "part name|part number")') as title_part_name_and_number
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio")')
        AND jsonb_path_exists(rov.description, 'strict $.title[0].**.type ? (@ like_regex "part name|part number")')
        AND jsonb_path_exists(rov.structural, '$.isMemberOf[*] ? (@ != "druid:yh583fk3400")')
        AND ro.head_version_id = rov.id
        AND ro.object_type = 'dro';
  SQL

  def self.report
    puts 'druid,catalogRecordId,title_part_number_before,title_part_name,title_part_number_after,collection_name,collection_id'
    rows.compact.each { |row| puts row }
  end

  def self.rows
    ActiveRecord::Base.connection.execute(SQL).to_a.map do |row|
      next if released_to_searchworks?(druid: row['druid'])

      collection_druid = row['collection_id']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      title_part_number_before, title_part_name, title_part_number_after = title_part_label_from(JSON.parse(row['title_part_name_and_number']))

      [
        row['druid'],
        row['catalog_record_id'],
        title_part_number_before,
        title_part_name,
        title_part_number_after,
        collection_name,
        collection_druid
      ].to_csv
    end
  end

  def self.title_part_label_from(title_part_list)
    part_number_position = title_part_list.index { |part| part['type'] == 'part number' }
    part_number = title_part_list.find { |part| part['type'] == 'part number' }&.[]('value')
    part_name = title_part_list.find { |part| part['type'] == 'part name' }&.[]('value')

    part_number_position == 0 ? [part_number, part_name, nil] : [nil, part_name, part_number] # rubocop:disable Style/NumericPredicate
  end

  def self.released_to_searchworks?(druid:)
    ReleaseTagService
      .for_public_metadata(cocina_object: CocinaObjectStore.find(druid))
      .any? { |tag| tag.to == 'Searchworks' && tag.release == true }
  end
end
