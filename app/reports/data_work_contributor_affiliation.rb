# frozen_string_literal: true

# see https://github.com/sul-dlss/dor-services-app/issues/5550
# Invoke via:
# bin/rails r -e production "DataWorkContributorAffiliation.report"
class DataWorkContributorAffiliation
  # Query for druids where a contributor has an affiliation note type instead of a proper affiliation node
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      rov.identification ->> 'sourceId' as sourceid,
      rov.identification ->> 'doi' as doi,
      jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
      jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
    FROM repository_objects AS ro, repository_object_versions AS rov
    WHERE ro.head_version_id = rov.id
      AND jsonb_path_exists(rov.description, '$.contributors[*].note[*] ? (@.type == "contributor")');
  SQL

  def self.report
    puts %w[druid sourceid title collection_druid collection_title doi].join(',')
    rows(SQL).each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      druid = row['druid']
      collection_druid = row['collection_druid']
      collection_title = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        druid,
        row['sourceid'],
        row['title'],
        collection_druid,
        collection_title,
        row['doi'],
      ].to_csv
    end
  end
end
