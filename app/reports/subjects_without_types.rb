# frozen_string_literal: true

# Report on DROs with subjects that have a value but no type.
# Checks two levels:
#   1. subject[*] where value exists but type does not
#   2. subject[*].structuredValue[*] where value exists but type does not
#
#  https://github.com/sul-dlss/dor-services-app/issues/5990
#
# Invoke via:
# bin/rails r -e production "SubjectsWithoutTypes.report"
class SubjectsWithoutTypes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES

  # Subjects with a value but no type
  SUBJECT_JSON_PATH = 'strict $.**.subject[*] ? (exists(@.value) && !(exists(@.type)))'
  # Structured values within subjects with a value but no type
  STRUCTURED_VALUE_JSON_PATH = 'strict $.**.subject[*].structuredValue[*] ? (exists(@.value) && !(exists(@.type)))'

  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier,
           jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo,
           jsonb_path_query_array(rov.description, '#{SUBJECT_JSON_PATH}.value') as subject_values,
           jsonb_path_query_array(rov.description, '#{STRUCTURED_VALUE_JSON_PATH}.value') as structured_values
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND (jsonb_path_exists(rov.description, '#{SUBJECT_JSON_PATH}')
           OR jsonb_path_exists(rov.description, '#{STRUCTURED_VALUE_JSON_PATH}'))
  SQL

  def self.report
    puts "druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    ActiveRecord::Base
      .connection
      .execute(sql_query)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        collection_druid = rows.first['collection_id']
        collection_head_version = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version
        if collection_head_version&.has_cocina?
          collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
        end
        apo_druid = rows.first['apo']
        apo_head_version = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version
        if apo_head_version&.has_cocina?
          apo_description = apo_head_version.to_cocina.description
          apo_name = Cocina::Models::Builders::TitleBuilder.build(apo_description.title) if apo_description
        end

        subject_values = rows.flat_map { |row| JSON.parse(row['subject_values']) }.uniq
        structured_values = rows.flat_map { |row| JSON.parse(row['structured_values']) }.uniq
        all_values = (subject_values + structured_values).uniq

        [
          id,
          all_values.join(';'),
          (rows.first['structured_title'] || rows.first['title'])&.delete("\n"),
          collection_druid,
          collection_name,
          rows.first['hrid'],
          apo_druid,
          apo_name
        ].to_csv
      end
  end
end
