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
  JSON_PATH = 'strict $.subject.**'
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier,
           events->'value' as value,
           jsonb_path_query(dros.identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros",
           jsonb_path_query(dros.description, '#{JSON_PATH} ? (@.value like_regex "--")') events
           WHERE
           jsonb_path_exists(description, '#{JSON_PATH}.value ? (@ like_regex "--")')
           AND (events->>'type' is null OR events->>'type' != 'map coordinates');

  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,uri,code,value\n"
    rows(SQL).each do |row|
      puts row
    end
  end

  def self.rows(sql)
    result = ActiveRecord::Base.connection.execute(sql)

    result.to_a.map do |row|
      [row['external_identifier'], row['catkey'], row['collection_id'], row['uri'], row['code'], "\"#{row['value']}\""].join(',')
    end
  end
end
