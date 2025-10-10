# frozen_string_literal: true

# see https://github.com/sul-dlss/dor-services-app/issues/5542
# Invoke via:
# bin/rails r -e production "DataWorkType.report"
class DataWorkType
  # Query for druids where work type is "Data" or work subtype is in the specified list.
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      rov.identification ->> 'sourceId' as sourceid,
      jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
      jsonb_path_query(rov.description, '$.form.structuredValue[*] ? (@.type == "type").value') ->> 0 as work_type,
      jsonb_path_query_array(rov.description, '$.form.structuredValue[*] ? (@.type == "subtype").value') as work_subtypes
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE ro.head_version_id = rov.id
      AND (
        jsonb_path_exists(rov.description, '$.form.structuredValue[*] ? (@.type == "type" && @.value == "Data")')
        OR
        jsonb_path_exists(rov.description, '$.form.structuredValue[*] ? (@.type == "subtype" && (@.value == "Data" || @.value == "Database" || @.value == "Geospatial data" || @.value == "Remote sensing imagery" || @.value == "Tabular data"))')
      );
  SQL

  def self.report
    puts %w[druid sourceid title collection_druid collection_title project_tag work_type work_subtypes content_type].join(',')
    rows(SQL).each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      druid = row['druid']
      collection_druid = row['collection_druid']
      collection_title = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label
      work_subtypes = JSON.parse(row['work_subtypes'] || '[]').join(',')
      object = RepositoryObject.find_by(external_identifier: druid)
      content_type = object&.head_version&.content_type
      project_tags = AdministrativeTag.where(druid:).map { |at| at.tag_label.tag }.join(',')

      [
        druid,
        row['sourceid'],
        row['title'],
        collection_druid,
        collection_title,
        project_tags,
        row['work_type'],
        work_subtypes,
        content_type
      ].to_csv
    end
  end
end
