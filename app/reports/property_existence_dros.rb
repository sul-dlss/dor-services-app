# frozen_string_literal: true

# Report dro objects with occurences of a property.

# Invoke via:
# bin/rails r -e production "PropertyExistenceDros.report"
class PropertyExistenceDros
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  # NOTE:  checking the size allows checking for only non-empty arrays;  we may have empty arrays, too.
  JSONB_PATH = 'strict $.**.contributor.parallelContributor ? (@.size() > 0)' # when property is array
  # JSONB_PATH = 'strict $.**.contributor.type' # when property is a string
  SQL = <<~SQL.squish.freeze
    SELECT external_identifier as item_druid,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(dros.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,collection_name\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        row['item_druid'],
        row['catkey'],
        collection_druid,
        "\"#{collection_name}\""
      ].join(',')
    end
  end
end
