# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "UnusualLanguageSourceUris.report"
class UnusualLanguageSourceUris
  JSON_PATH1 = '$.**.language.**.uri' # both language.uri and language.script.uri
  JSON_PATH2 = '$.**.valueLanguage.**.uri' # both valueLanguage.uri and valueLanguage.valueScript.uri
  # not "http(s)://id.loc.gov/vocabulary/iso639-2(/)"
  # or "http(s)://id.loc.gov/vocabulary/languages(/)"
  REGEX = '^(?!(http|https)(://id\.loc\.gov/vocabulary/(iso639-2|languages)/?)).*'
  SQL = <<~SQL.squish.freeze
    SELECT (jsonb_path_query_array(rov.description, '#{JSON_PATH1} ? (@ like_regex "#{REGEX}")') ||
            jsonb_path_query_array(rov.description, '#{JSON_PATH2} ? (@ like_regex "#{REGEX}")')) ->> 0 as value,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND ((jsonb_path_exists(rov.description, '#{JSON_PATH1} ? (@ like_regex "#{REGEX}")') OR
           jsonb_path_exists(rov.description, '#{JSON_PATH2} ? (@ like_regex "#{REGEX}")')
           ))
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,value\n"
    rows(SQL).each do |row|
      puts row
    end
  end

  def self.rows(sql)
    result = ActiveRecord::Base.connection.execute(sql)

    grouped = result.to_a.group_by { |row| row['external_identifier'] }
    grouped.map do |id, rows|
      value = rows.pluck('value').join(';')
      [id, rows.first['catalogRecordId'], rows.first['collection_id'], value].to_csv
    end
  end
end
