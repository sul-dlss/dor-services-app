# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidLocationUris.report"
class InvalidLocationUris
  JSON_PATH = '$.**.event.location'
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier, a #>> '{0,value}' as value, a #>> '{0,uri}' as uri, a #>> '{0,code}' as code,
           jsonb_path_query(dros.identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros",
           jsonb_path_query_array(dros.description, '#{JSON_PATH} ? (@.uri like_regex "^(?!https?://).*$" || @.uri like_regex "^.*\.html$")') a
           WHERE
           jsonb_path_exists(description, '#{JSON_PATH}.uri ? (@ like_regex "^(?!https?://).*$" || @ like_regex "^.*\.html$")')
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
