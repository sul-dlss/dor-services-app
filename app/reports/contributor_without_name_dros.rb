# frozen_string_literal: true

# Report on contributors with no name value that have role information

# Invoke via:
# bin/rails r -e production "ContributorWithoutNameDros.report"
class ContributorWithoutNameDros
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.**.contributor.**.name[*] ? (!(exists(@.value))) ? ((exists(@.role.code)) || (exists(@.role.value)) || (exists(@.role.uri)))'
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           desc_value->'role'->'code' as role_code,
           desc_value->'role'->'value' as role_value,
           desc_value->'role'->'uri' as role_uri,
           desc_value->'value' as name_value,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catalog_record_id
           FROM "dros",
           jsonb_path_query(dros.description, '#{JSONB_PATH}') desc_value
           WHERE
           jsonb_path_exists(dros.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts "item_druid,catalog_record_id,collection_druid,collection_name,name_value,role_code,role_value,role_uri\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        row['item_druid'],
        row['catalog_record_id'],
        collection_druid,
        "\"#{collection_name}\"",
        row['name_value'],
        row['role_code'],
        row['role_value'],
        row['role_uri']
      ].join(',')
    end
  end
end
