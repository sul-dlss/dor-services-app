# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidLocationUris.report"
class InvalidLocationUris
  JSON_PATH = '$.**.event.location.uri'
  SQL = <<~SQL.squish.freeze.squish
    SELECT (jsonb_path_query_array(description, '#{JSON_PATH} ? (@ like_regex "^.*\.html$")') ||
            jsonb_path_query_array(description, '#{JSON_PATH} ? (@ like_regex "^(?!https?://).*$")')) ->> 0 as value,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks.catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           (jsonb_path_exists(description, '#{JSON_PATH} ? (@ like_regex "^(?!https?://).*$")') OR
           jsonb_path_exists(description, '#{JSON_PATH} ? (@ like_regex "^.*\.html$")'))
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,value\n"
    rows(SQL).each do |row|
      puts row
    end
  end

  def self.rows(sql)
    result = ActiveRecord::Base.connection.execute(sql)

    grouped = result.to_a.group_by { |row| row['external_identifier'] }
    grouped.map do |id, rows|
      value = rows.map { |row| row['value'] }.join(';')
      [id, rows.first['catkey'], rows.first['collection_id'], value].join(',')
    end
  end
end
