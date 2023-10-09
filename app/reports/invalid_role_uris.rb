# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidRoleUris.report"
class InvalidRoleUris
  JSON_PATH = '$.**.contributor.role.uri'
  # These URIs have at least 2 trailing characters
  URL_PATTERNS = [
    'id\.loc\.gov/vocabulary/relators/..',
    'id\.loc\.gov/authorities/performanceMediums/..',
    'nomisma\.org/id/..'
  ].freeze
  REGEX = "\"^https?://(?!#{URL_PATTERNS.join('|')}).*$\"".freeze

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query_array(description, '#{JSON_PATH} ? (@ like_regex #{REGEX})') as value,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(description, '#{JSON_PATH} ? (@ like_regex #{REGEX})')
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
      value = rows.map { |row| JSON.parse(row['value']) }.join(';')
      [id, rows.first['catalogRecordId'], rows.first['collection_id'], value].join(',')
    end
  end
end
