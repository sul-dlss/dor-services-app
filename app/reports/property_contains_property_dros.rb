# frozen_string_literal: true

# Report on dros with specific property containing another specified property
#  it is expected the second property is an array, and we are selecting non-empty arrays with '? (@.size() > 0))'
#  To check for second property of type string, or to include empty arrays, remove '? (@.size() > 0))' from JSON_PATH

# Invoke via:
# bin/rails r -e production "PropertyContainsPropertyDros.report"
class PropertyContainsPropertyDros
  OUTER_PROPERTY = 'note'
  INNER_PROPERTY = 'identifier'

  # NOTE: {1 TO LAST} is needed if you're looking for a property inside the same property
  #   (e.g. structuredValue inside structuredValue), as .** includes itself
  #   see table 8.25 here https://www.postgresql.org/docs/current/datatype-json.html#JSON-INDEXING
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**.#{OUTER_PROPERTY} ? (exists(@.**{1 TO LAST}.#{INNER_PROPERTY} ? (@.size() > 0)))".freeze

  SQL_QUERY = <<~SQL.squish.freeze
    SELECT ro.external_identifier as object_druid,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as folio_instance_hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query(rov.description, '#{JSON_PATH}') ->> 0 as value
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts 'object_druid,collection_druid,folio_instance_hrid,value'

    ActiveRecord::Base.connection.execute(SQL_QUERY).to_a.each do |row|
      next if row.blank?

      puts [
        row['object_druid'],
        row['collection_druid'],
        row['folio_instance_hrid'],
        deep_compact_blank(JSON.parse(row['value']))
      ].to_csv
    end
  end

  def self.deep_compact_blank(maybe_enumerable)
    return maybe_enumerable unless maybe_enumerable.respond_to?(:compact_blank)

    maybe_enumerable
      .compact_blank
      .public_send(maybe_enumerable.is_a?(Hash) ? :transform_values : :map) { |value| deep_compact_blank(value) }
  end
end
