# frozen_string_literal: true

# Generate a report of DROs that have at leaste one event with a displayLabel
#
# bin/rails r -e production "PropertyEventsWithDisplayLabel.report"
#
class PropertyEventsWithDisplayLabel
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           dros.label as title,#{' '}
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query_array(dros.description, '$.event.displayLabel') as displayLabels,
           jsonb_path_query_first(dros.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') as catalogRecordId
           FROM "dros"
           WHERE jsonb_path_exists(dros.description, '$.event.displayLabel');
  SQL

  def self.report
    puts "item_druid,title,collection,catalog_record_id,display_labels\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_name = Collection.find_by(external_identifier: row['collection_druid'])&.label
      display_labels = JSON.parse(row['displaylabels']).map { |label| "\"#{label}\"" }.join(';')

      [
        row['item_druid'],
        row['title'],
        collection_name,
        row['catalogrecordid'],
        display_labels
      ].join(',')
    end
  end
end
