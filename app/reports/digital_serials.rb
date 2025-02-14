# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "DigitalSerials.report" > digital_serials.csv
class DigitalSerials
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  # https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  # relatedResource may be within a relatedResource, so we need to use .**
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier as druid,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalog_record_id,
      jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").refresh') ->> 0 as refresh
      FROM repository_objects AS ro, repository_object_versions AS rov WHERE
        jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio")')
        AND (jsonb_path_exists(rov.description, 'strict $.title.**.type ? (@ like_regex "part name|part number")')
        OR jsonb_path_exists(rov.description, 'strict $.note.**.type ? (@ like_regex "date\/sequential designation")'))
        AND ro.head_version_id = rov.id
        AND ro.object_type = 'dro';
  SQL

  def self.report
    puts 'druid,catalogRecordId,refresh\n'
    ActiveRecord::Base.connection.execute(SQL).each do |row|
      puts [row['druid'], row['catalog_record_id'], row['refresh']].join(',')
    end
  end
end
