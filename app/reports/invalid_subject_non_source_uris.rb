# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidSubjectNonSourceUris.report"
#
class InvalidSubjectNonSourceUris
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.subject[*] ? (!(exists(@.source.uri)))'
  # HT: https://stackoverflow.com/a/3809435
  REGEX = 'https?://(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,255}\.[a-zA-Z0-9()]{1,6}([-a-zA-Z0-9()@:%_\+.~#?&//=]*)'
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(description, '#{JSON_PATH} ? (!(@.**.uri like_regex "#{REGEX}")).**.uri') ->> 0 as invalid_values,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(description, '#{JSON_PATH} ? (!(@.**.uri like_regex "#{REGEX}")).**.uri')
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,collection_name,invalid_values\n"

    rows(SQL).each { |row| puts row if row }
  end

  def self.rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        collection_druid = rows.first['collection_id']
        collection_name = Collection.find_by(external_identifier: collection_druid)&.label

        [
          id,
          rows.first['catkey'],
          collection_druid,
          "\"#{collection_name}\"",
          rows.pluck('invalid_values').join(';')
        ].join(',')
      end
  end
end
