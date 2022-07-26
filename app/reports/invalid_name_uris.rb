# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidNameUris.report"
class InvalidNameUris
  JSON_PATH = '$.**.contributor.name.uri'
  SQL = <<~SQL.squish.freeze
    SELECT (jsonb_path_query_array(description, '#{JSON_PATH} ? (@ like_regex "^.*\.html$")') ||
            jsonb_path_query_array(description, '#{JSON_PATH} ? (@ like_regex "^(?!https?://).*$")')) ->> 0 as contrib,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
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
      contrib = rows.map { |row| row['contrib'] }.join(';')
      [id, rows.first['catkey'], rows.first['collection_id'], contrib].join(',')
    end
  end
end
