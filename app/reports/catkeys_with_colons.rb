# frozen_string_literal: true

# Find items that have catkeys containing colons

# Invoke via:
# bin/rails r -e production "CatkeysWithColons.report"
class CatkeysWithColons
  JSONB_CATKEY_PATH = '$.catalogLinks[*] ? (@.catalog == "symphony" || @.catalog == "previous symphony")'
  REGEX = '^[0-9]+(:[0-9]+)+$'

  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query(dros.identification, '#{JSONB_CATKEY_PATH}.catalogRecordId') ->> 0 as catkey
           FROM "dros" WHERE
           jsonb_path_exists(dros.identification, '#{JSONB_CATKEY_PATH} ? (@.catalogRecordId like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,collection_druid,catkeys\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_druid = row['collection_id']
      catkeys = JSON.parse(row['catkeys']).join(';') if row['catkeys'].present?

      [
        row['item_druid'],
        collection_druid,
        catkeys
      ].join(',')
    end
  end
end
