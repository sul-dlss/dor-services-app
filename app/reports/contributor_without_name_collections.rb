# frozen_string_literal: true

# Report on contributors with no name value that have role information

# Invoke via:
# bin/rails r -e production "ContributorWithoutNameCollections.report"
class ContributorWithoutNameCollections
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  # NOTE: I never figured out why the following line didn't work as expected
  # JSONB_PATH = 'strict $.**.contributor[*] ? (!(exists(@.name.**.value))) ? ((exists(@.role.code)) || (exists(@.role.value)) || (exists(@.role.uri)))'
  # NOTE: I ran each of the following four lines as separate reports
  JSONB_PATH = 'strict $.contributor[*] ? ( !exists(@.name.**.value) )' # top level
  # JSONB_PATH = 'strict $.**.event.contributor[*] ? ( !exists(@.name.**.value) )'
  # JSONB_PATH = 'strict $.**.adminMetadata.contributor[*] ? ( !exists(@.name.**.value) )'
  # JSONB_PATH = 'strict $.**.relatedResource.contributor[*] ? ( !exists(@.name.**.value) )'
  SQL = <<~SQL.squish.freeze
    SELECT collections.external_identifier as collection_druid,
           desc_value->'role'->'code' as role_code,
           desc_value->'role'->'value' as role_value,
           desc_value->'role'->'uri' as role_uri,
           desc_value->'value' as name_value,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catalog_record_id
           FROM "collections",
           jsonb_path_query(collections.description, '#{JSONB_PATH}') desc_value
           WHERE
           jsonb_path_exists(collections.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts "collection_druid,catalog_record_id,collection_name,name_value,role_code,role_value,role_uri\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label

      [
        collection_druid,
        row['catalog_record_id'],
        "\"#{collection_name}\"",
        row['name_value'],
        row['role_code'],
        row['role_value'],
        row['role_uri']
      ].join(',')
    end
  end
end
