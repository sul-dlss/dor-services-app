# frozen_string_literal: true

# Find URIs on the head versions of items known to have bad URIs in some version.

# Invoke via:
# bin/rails r -e production "ReportInvalidUris.report"
class ReportInvalidUris
  GOOD_URI = /\A#{URI::RFC2396_PARSER.make_regexp(['http', 'https'])}\z/

  def self.report
    puts "item_druid,hrid,collection_id,uri\n"
    File.foreach('app/reports/prod-druids-invalid-uri.txt') do |line|
      sql = <<~SQL.squish
        SELECT ro.external_identifier as item_druid,
              jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
              jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
              jsonb_path_query_array(rov.description, '$.**.uri') as uri
               FROM repository_objects AS ro, repository_object_versions AS rov WHERE
               ro.head_version_id = rov.id
               AND ro.external_identifier = '#{line.chomp}'
      SQL
      result = ActiveRecord::Base.connection.execute(sql)

      result.each do |row|
        bad_uris = JSON.parse(row['uri']).grep_v(GOOD_URI)
        bad_uris.each do |uri|
          puts [row['item_druid'], row['hrid'], row['collection_id'], "\"#{uri}\""].join(',')
        end
      end
    end
  end
end
