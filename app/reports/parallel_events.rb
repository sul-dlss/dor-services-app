# frozen_string_literal: true

# Report on DROs with parallelEvent in their description.
#  https://github.com/sul-dlss/dor-services-app/issues/5999
#
# Invoke via:
# bin/rails r -e production "ParallelEvents.report"
class ParallelEvents
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = 'strict $.**.parallelEvent ? (@.size() > 0)'

  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier,
           rov.label as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "druid,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

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
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label
        apo_druid = rows.first['apo']
        apo_name = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version&.label

        [
          id,
          rows.first['title']&.delete("\n"),
          collection_druid,
          collection_name,
          rows.first['hrid'],
          apo_druid,
          apo_name
        ].to_csv
      end
  end
end
