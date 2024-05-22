# frozen_string_literal: true

# Report on collections with specific property containing another specified property
#  it is expected the second property is an array, and we are selecting non-empty arrays with '? (@.size() > 0))'
#  To check for second property of type string, or to include empty arrays, remove '? (@.size() > 0))' from JSON_PATH

# Invoke via:
# bin/rails r -e production "PropertyContainsPropertyCollections.report"
class PropertyContainsPropertyCollections
  OUTER_PROPERTY = 'parallelValue'
  INNER_PROPERTY = 'structuredValue' # filters out empty arrays with ? (@.size() > 0)

  # NOTE: {1 TO LAST} is needed if you're looking for a property inside the same property
  #   (e.g. structuredValue inside structuredValue), as .** includes itself
  #   see table 8.25 here https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**.#{OUTER_PROPERTY} ? (exists(@.**{1 TO LAST}.#{INNER_PROPERTY} ? (@.size() > 0)))".freeze

  SQL = <<~SQL.squish.freeze
    SELECT external_identifier as collection_druid,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId
           FROM "collections" WHERE
           jsonb_path_exists(collections.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "collection_druid,catalogRecordId,collection_name,collections where #{OUTER_PROPERTY} contains #{INNER_PROPERTY}\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_name = RepositoryObject.collections.find_by(external_identifier: row['collection_druid'])&.head_version&.label

      [
        row['collection_druid'],
        row['catalogRecordId'],
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
