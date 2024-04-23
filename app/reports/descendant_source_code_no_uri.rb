# frozen_string_literal: true

# Report on properties with a descendant source.code without a corresponding uri.

# Invoke via:
# bin/rails r -e production "DescendantSourceCodeNoUri.report"
class DescendantSourceCodeNoUri
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.**.contributor.**.name[*] ? (exists(@.source.code)) ? (!(exists(@.uri)))'
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           desc_value->'source'->'code' as source_code,
           desc_value->'value' as name_value,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid
           FROM "dros",
           jsonb_path_query(dros.description, '#{JSONB_PATH}') desc_value
           WHERE
           NOT jsonb_path_exists(dros.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId')
           AND jsonb_path_exists(dros.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts "item_druid,collection_druid,collection_name,source_code\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_druid']
      collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version.label

      [
        row['item_druid'],
        collection_druid,
        "\"#{collection_name}\"",
        row['name_value'],
        row['source_code']
      ].join(',')
    end
  end
end
