# frozen_string_literal: true

# Generate a report of DROs that have at least one event with a displayLabel that is the direct child of relatedResource
#
# bin/rails r -e production "PropertyRelatedResourceEventsWithDisplayLabel.report"
#
class PropertyRelatedResourceEventsWithDisplayLabel
  SQL = <<~SQL.squish.freeze
    SELECT dros.external_identifier as item_druid,
           dros.label as title,
           jsonb_path_query(dros.structural, '$.isMemberOf') ->> 0 as collection_druid,
           jsonb_path_query_array(dros.description, '$.relatedResource[*].event.displayLabel') as displayLabels,
           jsonb_path_query_first(dros.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') as catalogRecordId
           FROM "dros"
           WHERE jsonb_path_exists(dros.description, '$.relatedResource[*].event.displayLabel');
  SQL

  def self.report
    puts "item_druid,title,collection,catalog_record_id,display_labels\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      collection_name = Collection.find_by(external_identifier: row['collection_druid'])&.label
      display_labels = JSON.parse(row['displaylabels']).join(';')

      [
        row['item_druid'],
        row['title'],
        collection_name,
        row['catalogrecordid'],
        display_labels
      ].join("\t")
    end
  end
end
