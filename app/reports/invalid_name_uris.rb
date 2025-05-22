# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidNameUris.report"
class InvalidNameUris
  JSON_PATH = '$.**.contributor.name.uri'
  # These URIs have at least 2 trailing characters
  URL_PATTERNS_IGNORED = [
    'id\.loc\.gov/authorities/names/..',
    'id\.loc\.gov/vocabulary/organizations/..',
    'vocab.getty.edu/ulan/..',
    'viaf.org/viaf/..'
  ].freeze
  REGEX = "\"^https?://(?!#{URL_PATTERNS_IGNORED.join('|')}).*$\"".freeze

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query_array(rov.description, '#{JSON_PATH} ? (@ like_regex #{REGEX})') as contrib,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex #{REGEX})')
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
      contrib = rows.map { |row| JSON.parse(row['contrib']) }.join(';')
      [id, rows.first['catalogRecordId'], rows.first['collection_id'], contrib].to_csv
    end
  end
end
