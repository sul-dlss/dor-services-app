# frozen_string_literal: true

# Report collection objects with occurences of a property.
#  it is expected the property is an array, and we are selecting non-empty arrays with '? (@.size() > 0))'
#  To check for property of type string, or to include empty arrays, remove '? (@.size() > 0))' from JSON_PATH

# Invoke via:
# bin/rails r -e production "PropertyExistenceCollections.report"
class PropertyExistenceCollections
  # NOTE: JSON_PATH may need to be changed, in addition to PROPERTY

  # this can be any JSON PATH desired, not just single property, e.g. 'contributor.type'
  PROPERTY = 'groupedValue' # could also be, e.g. 'contributor.type'

  # NOTE: checking the size allows checking for only non-empty arrays;  we may have empty arrays, too.
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**.#{PROPERTY} ? (@.size() > 0)".freeze # when property is array

  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as collection_druid,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'collection'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "collection_druid,catalogRecordId,collection_name,collections with #{PROPERTY}\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

      [
        collection_druid,
        row['catalogRecordId'],
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
