# frozen_string_literal: true

# Report on properties containing another specified property

# Invoke via:
# bin/rails r -e production "PropertyContainsPropertyCollections.report"
class PropertyContainsPropertyCollections
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  # {1 TO LAST} is needed if you're looking for a property inside the same property
  #   (e.g. structuredValue inside structuredValue), as .** includes itself
  #   see table 8.25 here https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING
  JSON_PATH = 'strict $.**.parallelValue ? (exists(@.**{1 TO LAST}.structuredValue ? (@.size() > 0)))'
  SQL = <<~SQL.squish.freeze
    SELECT external_identifier as collection_druid,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey
           FROM "collections" WHERE
           jsonb_path_exists(collections.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "collection_druid,catkey,collection_name\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_name = Collection.find_by(external_identifier: row['collection_druid'])&.label

      [
        row['collection_druid'],
        row['catkey'],
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
