# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidFormUris.report"
class InvalidFormUris
  JSON_PATH = '$.**.form.uri'
  SQL = <<~SQL.squish.freeze
    SELECT (jsonb_path_query_array(rov.description, '#{JSON_PATH} ? (@ like_regex "^.*\.html$")') ||
            jsonb_path_query_array(rov.description, '#{JSON_PATH} ? (@ like_regex "^(?!https?://).*$")')) ->> 0 as value,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND (jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "^(?!https?://).*$")') OR
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "^.*\.html$")'))
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
      [id, rows.first['catalogRecordId'], rows.first['collection_id'], value].join(',')
    end
  end
end
