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
    SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (!(@.**.uri like_regex "#{REGEX}")).**.uri') ->> 0 as invalid_values,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_verisons AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (!(@.**.uri like_regex "#{REGEX}")).**.uri')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,collection_name,invalid_values\n"

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
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.label

        [
          id,
          rows.first['catalogRecordId'],
          collection_druid,
          "\"#{collection_name}\"",
          rows.pluck('invalid_values').join(';')
        ].join(',')
      end
  end
end
