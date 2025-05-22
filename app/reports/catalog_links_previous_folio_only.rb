# frozen_string_literal: true

# Find items that have identification with catalogLink(s) that have "previous folio"

# Invoke via:
# bin/rails r -e production "CatalogLinksPreviousFolioOnly.report"
class CatalogLinksPreviousFolioOnly
  JSONB_FOLIO_LINKS_PATH = '$.catalogLinks[*] ? (@.catalog == "folio" && @.refresh == true)'
  JSONB_PREVIOUS_FOLIO_CLINK_PATH = '$.catalogLinks[*] ? (@.catalog == "previous folio")'

  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           jsonb_path_query_array(dros.identification, '#{JSONB_FOLIO_LINKS_PATH}.catalogRecordId') as folios,
           jsonb_path_query_array(dros.identification, '#{JSONB_PREVIOUS_FOLIO_CLINK_PATH}.catalogRecordId') as previous_folios
           FROM "dros" WHERE
           jsonb_path_exists(dros.identification, '#{JSONB_PREVIOUS_FOLIO_CLINK_PATH}')
  SQL

  def self.report
    puts "item_druid,folios,previous_folios\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      folios = JSON.parse(row['folios']).join(';') if row['folios'].present?
      previous_folios = JSON.parse(row['previous_folios']).join(';') if row['previous_folios'].present?

      [
        row['item_druid'],
        folios,
        previous_folios
      ].to_csv
    end
  end
end
