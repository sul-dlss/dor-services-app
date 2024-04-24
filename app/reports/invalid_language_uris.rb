# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidLanguageUris.report"
class InvalidLanguageUris
  JSON_PATH1 = '$.**.language.**.uri' # both language.uri and language.script.uri
  JSON_PATH2 = '$.**.valueLanguage.**.uri' # both valueLanguage.uri and valueLanguage.valueScript.uri

  SQL = <<~SQL.squish.freeze
    SELECT (jsonb_path_query_array(rov.description, '#{JSON_PATH1} ? (@ like_regex "^.*\.html$")') ||
            jsonb_path_query_array(rov.description, '#{JSON_PATH1} ? (@ like_regex "^(?!https?://).*$")') ||
            jsonb_path_query_array(rov.description, '#{JSON_PATH2} ? (@ like_regex "^.*\.html$")') ||
            jsonb_path_query_array(rov.description, '#{JSON_PATH2} ? (@ like_regex "^(?!https?://).*$")')) ->> 0 as contrib,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_verisons AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND ((jsonb_path_exists(rov.description, '#{JSON_PATH1} ? (@ like_regex "^(?!https?://).*$")') OR
           jsonb_path_exists(rov.description, '#{JSON_PATH1} ? (@ like_regex "^.*\.html$")') OR
           jsonb_path_exists(rov.description, '#{JSON_PATH2} ? (@ like_regex "^(?!https?://).*$")') OR
           jsonb_path_exists(rov.description, '#{JSON_PATH2} ? (@ like_regex "^.*\.html$")')
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
      contrib = rows.pluck('contrib').join(';')
      [id, rows.first['catalogRecordId'], rows.first['collection_id'], contrib].join(',')
    end
  end
end
