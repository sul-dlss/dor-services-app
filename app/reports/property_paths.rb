# frozen_string_literal: true

# NOTE: This report may not be run via the read-only connection onsdr-infra since it relies upon `CREATE FUNCTION`
#
# Report any objects with occurrences of a property and the paths to the property.
#  it is expected the property is an array, and we are selecting non-empty arrays with '? (@.size() > 0))'
#  To check for property of type string, or to include empty arrays, remove '? (@.size() > 0))' from JSON_PATH

# Invoke via:
# bin/rails r -e production "PropertyPaths.report"
class PropertyPaths
  # NOTE: JSON_PATH may need to be changed, in addition to PROPERTY

  # this can be any JSON PATH desired, not just single property, e.g. 'contributor.type'
  PROPERTY = 'groupedValue' # could also be, e.g. 'contributor.type'

  # NOTE: checking the size allows checking for only non-empty arrays;  we may have empty arrays, too.
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**.#{PROPERTY} ? (@.size() > 0)".freeze # when property is array

  # HT: https://dba.stackexchange.com/a/310127
  SQL_QUERY = <<~SQL.squish.freeze
    CREATE OR REPLACE FUNCTION jsonb_paths (data jsonb, prefix text[]) RETURNS SETOF text[] LANGUAGE plpgsql AS $$
    DECLARE
      key text;
      value jsonb;
      path text[];
      counter integer := 0;
    BEGIN
      IF jsonb_typeof(data) = 'object' THEN
        FOR key, value IN SELECT * FROM jsonb_each(data) LOOP
          IF jsonb_typeof(value) IN ('array', 'object') THEN
            RETURN QUERY SELECT * FROM jsonb_paths (value, array_append(prefix, key));
          ELSE
            RETURN NEXT array_append(prefix, key);
          END IF;
        END LOOP;
      ELSIF jsonb_typeof(data) = 'array' THEN
        FOR value IN SELECT * FROM jsonb_array_elements(data) LOOP
          IF jsonb_typeof(value) IN ('array', 'object') THEN
            RETURN QUERY SELECT * FROM jsonb_paths (value, array_append(prefix, counter::text));
          ELSE
            RETURN NEXT array_append(prefix, counter::text);
          END IF;
          counter := counter + 1;
        END LOOP;
      END IF;
    END
    $$;
    SELECT ro.external_identifier as object_druid,
           ro.object_type as object_type,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as folio_instance_hrid,
           property_path
           FROM repository_objects AS ro, repository_object_versions AS rov, jsonb_paths(rov.description, '{}') property_path
           WHERE property_path @> '{groupedValue}'
           AND ro.head_version_id = rov.id
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "object_druid,collection_druid,folio_instance_hrid,#{PROPERTY}_path"
    ActiveRecord::Base.connection.execute(SQL_QUERY).to_a.each do |row|
      next if row.blank?

      puts [
        row['object_druid'],
        row['object_type'],
        row['collection_druid'],
        row['folio_instance_hrid'],
        row['property_path']
      ].to_csv
    end
  end
end
