# frozen_string_literal: true

# Find items that have identification with catalogLink(s) with catalog "previous symphony"

# Invoke via:
# bin/rails r -e production "CatalogLinksPreviousSymphony.report"
class CatalogLinksPreviousSymphony
  JSONB_CKEY_CATALOG_LINKS_PATH = '$.catalogLinks[*] ? (@.catalog == "symphony")'
  JSONB_PREVIOUS_CKEY_CLINK_PATH = '$.catalogLinks[*] ? (@.catalog == "previous symphony")'

  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query_array(dros.identification, '#{JSONB_CKEY_CATALOG_LINKS_PATH}.catalogRecordId') as catkeys,
           jsonb_path_query_array(dros.identification, '#{JSONB_PREVIOUS_CKEY_CLINK_PATH}.catalogRecordId') as previous_catkeys
           FROM "dros" WHERE
           jsonb_path_exists(dros.identification, '#{JSONB_PREVIOUS_CKEY_CLINK_PATH}')
  SQL

  def self.report
    puts "item_druid,collection_druid,collection_name,catkeys,previous_catkeys\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      collection_name = Collection.find_by(external_identifier: collection_druid)&.label
      catkeys = JSON.parse(row['catkeys']).join(';') if row['catkeys'].present?
      prev_catkeys = JSON.parse(row['previous_catkeys']).join(';') if row['previous_catkeys'].present?

      [
        row['item_druid'],
        collection_druid,
        "\"#{collection_name}\"",
        catkeys,
        prev_catkeys
      ].join(',')
    end
  end
end
