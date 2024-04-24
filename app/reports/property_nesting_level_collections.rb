# frozen_string_literal: true

# Report collection objects with occurences of a property at least N nesting levels in.

# Invoke via:
# bin/rails r -e production "PropertyNestingLevelCollections.report"
class PropertyNestingLevelCollections
  MIN_NESTING_LEVEL = 7
  PROPERTY = 'valueScript' # this could also be, e.g. contributor.type

  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**{#{MIN_NESTING_LEVEL} TO LAST}.#{PROPERTY}".freeze
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as collection_druid,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'collection'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "collection_druid,catalogRecordId,collection_name,nesting level of #{PROPERTY} #{MIN_NESTING_LEVEL} or higher\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.label

      [
        collection_druid,
        row['catalogRecordId'],
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
