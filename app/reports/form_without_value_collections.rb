# frozen_string_literal: true

# Report on form with no value that have source and/or type information

# Invoke via:
# bin/rails r -e production "FormWithoutValueCollections.report"
class FormWithoutValueCollections
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.**.form.**.value[*] ? (!(exists(@.value))) ? ((exists(@.type)) || (exists(@.source.code)) || (exists(@.source.value)) || (exists(@.source.uri)))'
  SQL = <<~SQL.squish.freeze
    SELECT collections.external_identifier as collection_druid,
           desc_value->'value' as form_value,
           desc_value->'type' as form_type,
           desc_value->'source'->'code' as source_code,
           desc_value->'source'->'value' as source_value,
           desc_value->'source'->'uri' as source_uri,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catalog_record_id
           FROM "collections",
           jsonb_path_query(collections.description, '#{JSONB_PATH}') desc_value
           WHERE
           jsonb_path_exists(collections.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts "collection_druid,catalog_record_id,collection_name,form_value,form_type,source_code,source_value,source_uri\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        collection_druid,
        row['catalog_record_id'],
        "\"#{collection_name}\"",
        row['form_value'],
        row['form_type'],
        row['source_code'],
        row['source_value'],
        row['source_uri']
      ].join(',')
    end
  end
end
