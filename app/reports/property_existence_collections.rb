# frozen_string_literal: true

# Report collection objects with occurences of a property.

# Invoke via:
# bin/rails r -e production "PropertyExistenceCollections.report"
class PropertyExistenceCollections
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.**.groupedValue ? (@.size() > 0)' # when property is array
  # JSONB_PATH = 'strict $.**.contributor.type' # when property is a string - maybe keep size check to avoid empty values
  SQL = <<~SQL.squish.freeze
    SELECT external_identifier as collection_druid,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey
           FROM "collections" WHERE
           jsonb_path_exists(collections.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts "collection_druid,catkey,collection_name\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        collection_druid,
        row['catkey'],
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
