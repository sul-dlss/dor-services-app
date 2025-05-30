# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidLocationUris.report"
class InvalidLocationUris
  JSON_PATH = '$.**.event.location'
  # These URIs have at least 2 trailing characters
  URL_PATTERNS_IGNORED = [
    'id\.loc\.gov/authorities/names/..',
    'id.loc.gov/vocabulary/geographicAreas/..',
    'id.loc.gov/vocabulary/countries/..',
    'www.geonames.org/..',
    'www.wikidata.org/wiki/..'
  ].freeze
  REGEX = "\"^https?://(?!#{URL_PATTERNS_IGNORED.join('|')}).*$\"".freeze
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier,
           event_location #>> '{0,value}' as value,
           event_location #>> '{0,uri}' as uri,
           event_location #>> '{0,code}' as code,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro,
           repository_object_versions AS rov,
           jsonb_path_query_array(rov.description, '#{JSON_PATH} ? (@.uri like_regex #{REGEX})') AS event_location
           WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           ANd jsonb_path_exists(rov.description, '#{JSON_PATH}.uri ? (@ like_regex #{REGEX})')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,uri,code,value\n"
    rows(SQL).each do |row|
      puts row
    end
  end

  def self.rows(sql)
    result = ActiveRecord::Base.connection.execute(sql)

    result.to_a.map do |row|
      [row['external_identifier'], row['catalogRecordId'], row['collection_id'], row['uri'], row['code'],
       row['value']].to_csv
    end
  end
end
