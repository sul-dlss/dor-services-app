# frozen_string_literal: true

# Find items that have catalogRecordIds containing colons

# Invoke via:
# bin/rails r -e production "CatalogRecordIdsWithColons.report"
class CatalogRecordIdsWithColons
  JSONB_CATALOG_RECORD_ID_PATH = '$.catalogLinks[*] ? (@.catalog == "folio" || @.catalog == "previous folio")'
  REGEX = '^[0-9]+(:[0-9]+)+$'

  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query(dros.identification, '#{JSONB_CATALOG_RECORD_ID_PATH}.catalogRecordId') ->> 0 as catalogRecordId
           FROM "dros" WHERE
           jsonb_path_exists(dros.identification, '#{JSONB_CATALOG_RECORD_ID_PATH} ? (@.catalogRecordId like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,collection_druid,catalogRecordIds\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      catalog_record_ids = JSON.parse(row['catalogRecordIds']).join(';') if row['catalogRecordIds'].present?

      [
        row['item_druid'],
        collection_druid,
        catalog_record_ids
      ].to_csv
    end
  end
end
