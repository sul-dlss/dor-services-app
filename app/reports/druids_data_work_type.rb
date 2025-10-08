# frozen_string_literal: true

# see https://github.com/sul-dlss/dor-services-app/issues/5542
# Invoke via:
# bin/rails r -e production "DruidsDataWorkType.report"
class DruidsDataWorkType
  # Query for druids where work type is "Data" or work subtype is in the specified list.
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      rov.identification ->> 'sourceId' as sourceid,
      jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
      jsonb_path_query(rov.administrative, '$.tags[*] ? (@.type == "Project").value') ->> 0 as project_tag,
      jsonb_path_query(rov.structural, '$.form.structuredValue[*] ? (@.type == "type").value') ->> 0 as work_type,
      jsonb_path_query_array(rov.structural, '$.form.structuredValue[*] ? (@.type == "subtype").value') as work_subtypes,
      jsonb_path_query(rov.structural, '$.form.structuredValue[*] ? (@.type == "content type").value') ->> 0 as content_type
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE ro.head_version_id = rov.id
      AND (
        jsonb_path_exists(rov.structural, '$.form.structuredValue[*] ? (@.type == "type" && @.value == "Data")')
        OR
        jsonb_path_exists(rov.structural, '$.form.structuredValue[*] ? (@.type == "subtype" && @.value in ("Data", "Database", "Geospatial data", "Remote sensing imagery", "Tabular data"))')
      );
  SQL

  def self.report
    puts %w[druid sourceid title collection_druid collection_title project_tag work_type work_subtypes content_type].join(',')
    rows(SQL).each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_title = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label
      work_subtypes = row['work_subtypes']&.join(',') || ''

      [
        row['druid'],
        row['sourceid'],
        row['title'],
        collection_druid,
        collection_title,
        row['project_tag'],
        row['work_type'],
        work_subtypes,
        row['content_type']
      ].to_csv
    end
  end
end
