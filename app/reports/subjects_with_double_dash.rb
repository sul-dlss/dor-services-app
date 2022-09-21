# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "SubjectsWithDoubleDash.report"
#
class SubjectsWithDoubleDash
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.subject.**'
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier,
           subjects->'value' as value,
           subjects->'source'->'code' as code,
           jsonb_path_query(dros.identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros",
           jsonb_path_query(dros.description, '#{JSONB_PATH} ? (@.value like_regex "--")') subjects
           WHERE
           jsonb_path_exists(description, '#{JSONB_PATH}.value ? (@ like_regex "--")')
           AND (subjects->>'type' is null OR subjects->>'type' != 'map coordinates')
           AND subjects->'source'->>'code' IN ('lcsh', 'naf')
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,collection_name,value\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        row['external_identifier'],
        row['catkey'],
        collection_druid,
        "\"#{collection_name}\"",
        "\"#{row['value']}\""
      ].join(',')
    end
  end
end
