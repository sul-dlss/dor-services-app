# frozen_string_literal: true

# Report on dros with parallel contributors

# Invoke via:
# bin/rails r -e production "ParallelContributors.report"
class ParallelContributors
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = 'strict $.contributor.**.parallelContributor ? (@.size() > 0)'

  SQL_QUERY = <<~SQL.squish.freeze
    SELECT ro.external_identifier as object_druid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as folio_instance_hrid
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts 'object_druid,collection_druid,folio_instance_hrid'

    ActiveRecord::Base.connection.execute(SQL_QUERY).to_a.each do |row|
      next if row.blank?

      puts [
        row['object_druid'],
        row['collection_druid'],
        row['folio_instance_hrid']
      ].to_csv
    end
  end
end
